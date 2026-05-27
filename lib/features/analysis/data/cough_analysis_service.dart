import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_app/core/models/analysis_record.dart';
import 'package:cloud_app/core/models/condition_probability.dart';
import 'package:cloud_app/features/analysis/data/analysis_inference_backend.dart';
import 'package:cloud_app/features/analysis/data/mel_spectrogram.dart';
import 'package:cloud_app/features/analysis/data/spectrogram_export_service.dart';
import 'package:cloud_app/features/analysis/data/wav_reader.dart';
import 'package:cloud_app/features/analysis/domain/recorded_cough.dart';

import 'native_tflite_inference_backend.dart'
    if (dart.library.js_interop) 'web_js_inference_backend.dart'
    as backend_factory;

typedef WavSampleReader = List<double> Function(Uint8List wavBytes);
typedef MelSpectrogramComputer =
    List<List<double>> Function(List<double> samples);
typedef SpectrogramExporter =
    Future<SpectrogramExportResult> Function({
      required String analysisId,
      required List<List<double>> melSpectrogram,
    });

class CoughAnalysisService {
  CoughAnalysisService({
    required AnalysisInferenceBackend backend,
    Future<List<String>> Function()? loadLabels,
    WavSampleReader? readWavSamples,
    MelSpectrogramComputer? computeMelSpectrogram,
    SpectrogramExporter? exportSpectrogram,
    String Function()? generateId,
    DateTime Function()? now,
    this.inputHeight = 128,
    this.inputWidth = 128,
    this.inputChannels = 1,
  }) : _backend = backend,
       _loadLabels = loadLabels,
       _readWavSamples = readWavSamples,
       _computeMelSpectrogram = computeMelSpectrogram,
       _exportSpectrogram = exportSpectrogram,
       _generateId = generateId,
       _now = now;

  static const labelsAssetPath = 'assets/models/labels.txt';

  final AnalysisInferenceBackend _backend;
  final Future<List<String>> Function()? _loadLabels;
  final WavSampleReader? _readWavSamples;
  final MelSpectrogramComputer? _computeMelSpectrogram;
  final SpectrogramExporter? _exportSpectrogram;
  final String Function()? _generateId;
  final DateTime Function()? _now;

  final int inputHeight;
  final int inputWidth;
  final int inputChannels;

  Future<AnalysisRecord> analyze(RecordedCough recordedCough) async {
    final analysisId = _generateId?.call() ?? _defaultGenerateId();
    final labels = await (_loadLabels ?? _defaultLoadLabels)();
    final wavSamples = (_readWavSamples ?? WavReader.readMono16BitPcmBytes)(
      recordedCough.wavBytes,
    );
    if (wavSamples.isEmpty) {
      throw StateError(
        'Recorded cough audio did not contain valid 16-bit PCM WAV samples.',
      );
    }
    final melSpectrogram = (_computeMelSpectrogram ??
        _defaultComputeMelSpectrogram)(wavSamples);
    final preparedInput = _prepareInput(
      melSpectrogram,
      height: inputHeight,
      width: inputWidth,
      channels: inputChannels,
    );
    final scores = await _backend.infer(
      input: preparedInput,
      height: inputHeight,
      width: inputWidth,
      channels: inputChannels,
    );

    if (labels.isEmpty) {
      throw StateError('No analysis labels were loaded from $labelsAssetPath.');
    }
    if (scores.isEmpty) {
      throw StateError('Inference backend returned no scores.');
    }
    if (labels.length != scores.length) {
      throw StateError(
        'Expected ${labels.length} scores for the loaded labels, but received '
        '${scores.length}.',
      );
    }

    final probabilities = labels.indexed
        .map((entry) {
          final index = entry.$1;
          final label = entry.$2;
          return ConditionProbability(
            name: label,
            percentage: (scores[index] * 100).round().clamp(0, 100),
            hexColor: _colorForLabel(label, index),
          );
        })
        .toList(growable: false)
      ..sort((a, b) => b.percentage.compareTo(a.percentage));

    final exportResult = await (_exportSpectrogram ?? _missingExporter)(
      analysisId: analysisId,
      melSpectrogram: melSpectrogram,
    );
    final topProbability = probabilities.first;

    return AnalysisRecord(
      id: analysisId,
      date: _now?.call() ?? DateTime.now(),
      condition: topProbability.name,
      percentage: topProbability.percentage,
      probabilities: probabilities,
      audioFilePath: null,
      spectrogramFilePath: exportResult.spectrogramFilePath,
      repoMirrorPath: exportResult.repoMirrorPath,
      storageBackend: exportResult.storageBackend,
    );
  }

  Float32List _prepareInput(
    List<List<double>> melSpectrogram, {
    required int height,
    required int width,
    required int channels,
  }) {
    final resized = _resizeMelSpectrogram(
      melSpectrogram,
      targetHeight: height,
      targetWidth: width,
    );
    final finiteValues =
        resized.expand((row) => row).where((value) => value.isFinite).toList();
    final minValue =
        finiteValues.isEmpty ? 0.0 : finiteValues.reduce(_minDouble);
    final maxValue =
        finiteValues.isEmpty ? 0.0 : finiteValues.reduce(_maxDouble);
    final range = maxValue - minValue;
    final prepared = Float32List(height * width * channels);
    var offset = 0;

    for (final row in resized) {
      for (final value in row) {
        final sanitized = value.isFinite ? value : minValue;
        final normalized =
            range <= 0 ? 0.0 : ((sanitized - minValue) / range).clamp(0.0, 1.0);
        for (var channel = 0; channel < channels; channel += 1) {
          prepared[offset] = normalized.toDouble();
          offset += 1;
        }
      }
    }

    return prepared;
  }

  List<List<double>> _resizeMelSpectrogram(
    List<List<double>> melSpectrogram, {
    required int targetHeight,
    required int targetWidth,
  }) {
    if (targetHeight <= 0 || targetWidth <= 0) {
      throw ArgumentError('Model input dimensions must be positive.');
    }
    if (melSpectrogram.isEmpty) {
      return List.generate(
        targetHeight,
        (_) => List<double>.filled(targetWidth, 0.0),
      );
    }

    final sourceHeight = melSpectrogram.length;
    final sourceWidth = melSpectrogram.fold<int>(
      1,
      (maxWidth, row) => row.length > maxWidth ? row.length : maxWidth,
    );

    return List.generate(targetHeight, (y) {
      final sourceY = ((y * sourceHeight) / targetHeight).floor().clamp(
        0,
        sourceHeight - 1,
      );
      final sourceRow = melSpectrogram[sourceY];
      return List<double>.generate(targetWidth, (x) {
        if (sourceRow.isEmpty) {
          return 0.0;
        }
        final sourceX = ((x * sourceWidth) / targetWidth).floor().clamp(
          0,
          sourceWidth - 1,
        );
        return sourceX < sourceRow.length ? sourceRow[sourceX] : 0.0;
      }, growable: false);
    }, growable: false);
  }

  Future<List<String>> _defaultLoadLabels() async {
    try {
      final rawLabels = await rootBundle.loadString(labelsAssetPath);
      final labels = rawLabels
          .split('\n')
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList(growable: false);
      if (labels.isEmpty) {
        throw StateError('No labels were defined in $labelsAssetPath.');
      }
      return labels;
    } on FlutterError catch (_) {
      throw StateError(
        'Analysis labels are missing at $labelsAssetPath. '
        'Add and register the real labels.txt file before running analysis.',
      );
    }
  }

  List<List<double>> _defaultComputeMelSpectrogram(List<double> samples) {
    return MelSpectrogram.compute(
      samples: samples,
      sampleRate: 16000,
      fftSize: 1024,
      hopLength: 256,
      melBins: 128,
      minFreq: 20,
      maxFreq: 8000,
    );
  }

  String _defaultGenerateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  Future<SpectrogramExportResult> _missingExporter({
    required String analysisId,
    required List<List<double>> melSpectrogram,
  }) {
    throw StateError('No spectrogram exporter has been configured.');
  }

  int _colorForLabel(String label, int index) {
    const knownColors = <String, int>{
      'Healthy': 0xFF22C55E,
      'Bronchitis': 0xFFFAB95B,
      'Asthma': 0xFF547792,
      'Pneumonia': 0xFFEF4444,
      'COVID-19': 0xFFEF4444,
      'Lung Cancer': 0xFF991B1B,
    };
    const fallbackPalette = <int>[
      0xFF4F46E5,
      0xFF06B6D4,
      0xFFF97316,
      0xFF8B5CF6,
      0xFF0F766E,
    ];

    return knownColors[label] ??
        fallbackPalette[index % fallbackPalette.length];
  }

  double _minDouble(double a, double b) => a < b ? a : b;

  double _maxDouble(double a, double b) => a > b ? a : b;
}

final analysisInferenceBackendProvider = Provider<AnalysisInferenceBackend>(
  (ref) => backend_factory.createDefaultAnalysisInferenceBackend(),
);

final coughAnalysisServiceProvider = Provider<CoughAnalysisService>((ref) {
  final exportService = ref.watch(spectrogramExportServiceProvider);
  return CoughAnalysisService(
    backend: ref.watch(analysisInferenceBackendProvider),
    exportSpectrogram:
        ({
          required String analysisId,
          required List<List<double>> melSpectrogram,
        }) => exportService.export(
          analysisId: analysisId,
          melSpectrogram: melSpectrogram,
        ),
  );
});
