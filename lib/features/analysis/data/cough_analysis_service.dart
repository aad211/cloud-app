import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
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

class DebugAnalysisResult {
  const DebugAnalysisResult({
    required this.modelHeight,
    required this.modelWidth,
    required this.modelChannels,
    required this.wavSampleCount,
    required this.melSpectrogram,
    required this.preparedInput,
    required this.labels,
    required this.rawScores,
    required this.stageDurationsMs,
    required this.melPreviewPngBytes,
    required this.preparedInputPreviewPngBytes,
  });

  final int modelHeight;
  final int modelWidth;
  final int modelChannels;
  final int wavSampleCount;
  final List<List<double>> melSpectrogram;
  final Float32List preparedInput;
  final List<String> labels;
  final List<double> rawScores;
  final Map<String, int> stageDurationsMs;
  final Uint8List melPreviewPngBytes;
  final Uint8List preparedInputPreviewPngBytes;
}

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

  static const labelsAssetPath = 'assets/labels.txt';

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

    // Get the model's expected input shape dynamically
    final expectedShape = await _backend.getExpectedInputShape();
    final modelHeight = expectedShape[0];
    final modelWidth = expectedShape[1];
    final modelChannels = expectedShape[2];

    final melSpectrogram = (_computeMelSpectrogram ??
        _defaultComputeMelSpectrogram)(wavSamples);
    final preparedInput = _prepareInput(
      melSpectrogram,
      height: modelHeight,
      width: modelWidth,
      channels: modelChannels,
    );
    final scores = await _backend.infer(
      input: preparedInput,
      height: modelHeight,
      width: modelWidth,
      channels: modelChannels,
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

  Future<DebugAnalysisResult> buildDebugAnalysis(
    RecordedCough recordedCough,
  ) async {
    final stageDurations = <String, int>{};

    final labelsTimer = Stopwatch()..start();
    final labels = await (_loadLabels ?? _defaultLoadLabels)();
    labelsTimer.stop();
    stageDurations['Load labels'] = labelsTimer.elapsedMilliseconds;

    final wavTimer = Stopwatch()..start();
    final wavSamples = (_readWavSamples ?? WavReader.readMono16BitPcmBytes)(
      recordedCough.wavBytes,
    );
    wavTimer.stop();
    stageDurations['Decode WAV'] = wavTimer.elapsedMilliseconds;
    if (wavSamples.isEmpty) {
      throw StateError(
        'Recorded cough audio did not contain valid 16-bit PCM WAV samples.',
      );
    }

    final shapeTimer = Stopwatch()..start();
    final expectedShape = await _backend.getExpectedInputShape();
    shapeTimer.stop();
    stageDurations['Read model shape'] = shapeTimer.elapsedMilliseconds;
    final modelHeight = expectedShape[0];
    final modelWidth = expectedShape[1];
    final modelChannels = expectedShape[2];

    final melTimer = Stopwatch()..start();
    final melSpectrogram = (_computeMelSpectrogram ??
        _defaultComputeMelSpectrogram)(wavSamples);
    melTimer.stop();
    stageDurations['Compute mel spectrogram'] = melTimer.elapsedMilliseconds;

    final preprocessTimer = Stopwatch()..start();
    final preparedInput = _prepareInput(
      melSpectrogram,
      height: modelHeight,
      width: modelWidth,
      channels: modelChannels,
    );
    preprocessTimer.stop();
    stageDurations['Prepare model input'] = preprocessTimer.elapsedMilliseconds;

    final inferTimer = Stopwatch()..start();
    final scores = await _backend.infer(
      input: preparedInput,
      height: modelHeight,
      width: modelWidth,
      channels: modelChannels,
    );
    inferTimer.stop();
    stageDurations['Run inference'] = inferTimer.elapsedMilliseconds;

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

    final renderTimer = Stopwatch()..start();
    final melPreviewPngBytes = await _renderDebugPngBytes(melSpectrogram);
    final preparedPreviewMatrix = _buildPreparedInputPreviewMatrix(
      preparedInput: preparedInput,
      height: modelHeight,
      width: modelWidth,
      channels: modelChannels,
    );
    final preparedInputPreviewPngBytes = await _renderDebugPngBytes(
      preparedPreviewMatrix,
    );
    renderTimer.stop();
    stageDurations['Render previews'] = renderTimer.elapsedMilliseconds;

    return DebugAnalysisResult(
      modelHeight: modelHeight,
      modelWidth: modelWidth,
      modelChannels: modelChannels,
      wavSampleCount: wavSamples.length,
      melSpectrogram: melSpectrogram,
      preparedInput: preparedInput,
      labels: labels,
      rawScores: scores,
      stageDurationsMs: stageDurations,
      melPreviewPngBytes: melPreviewPngBytes,
      preparedInputPreviewPngBytes: preparedInputPreviewPngBytes,
    );
  }

  List<List<double>> _buildPreparedInputPreviewMatrix({
    required Float32List preparedInput,
    required int height,
    required int width,
    required int channels,
  }) {
    final preview = List.generate(
      height,
      (_) => List<double>.filled(width, 0),
      growable: false,
    );
    var offset = 0;
    for (var y = 0; y < height; y += 1) {
      for (var x = 0; x < width; x += 1) {
        preview[y][x] = preparedInput[offset];
        offset += channels;
      }
    }
    return preview;
  }

  Future<Uint8List> _renderDebugPngBytes(List<List<double>> matrix) async {
    final height = matrix.isEmpty ? 1 : matrix.length;
    final width = matrix.fold<int>(
      1,
      (maxWidth, row) => row.length > maxWidth ? row.length : maxWidth,
    );
    final values = <double>[];
    for (final row in matrix) {
      for (final value in row) {
        if (value.isFinite) {
          values.add(value);
        }
      }
    }
    final minValue = values.isEmpty ? 0.0 : values.reduce(_minDouble);
    final maxValue = values.isEmpty ? 0.0 : values.reduce(_maxDouble);
    final range = maxValue - minValue;
    final pixels = Uint8List(width * height * 4);

    for (var y = 0; y < height; y += 1) {
      final sourceY = height - 1 - y;
      final row = sourceY < matrix.length ? matrix[sourceY] : const <double>[];
      for (var x = 0; x < width; x += 1) {
        final rawValue = x < row.length && row[x].isFinite ? row[x] : minValue;
        final normalized =
            range <= 0 ? 0.0 : ((rawValue - minValue) / range).clamp(0.0, 1.0);
        final color = _infernoColor(normalized);
        final pixelOffset = (y * width + x) * 4;
        pixels[pixelOffset] = color.$1;
        pixels[pixelOffset + 1] = color.$2;
        pixels[pixelOffset + 2] = color.$3;
        pixels[pixelOffset + 3] = 255;
      }
    }

    final image = await _decodeImageFromPixels(
      pixels,
      width: width,
      height: height,
    );
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Failed to encode debug preview PNG bytes.');
      }
      return byteData.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<ui.Image> _decodeImageFromPixels(
    Uint8List pixels, {
    required int width,
    required int height,
  }) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  (int, int, int) _infernoColor(double value) {
    const palette = <(double, int, int, int)>[
      (0.0, 0, 0, 4),
      (0.13, 31, 12, 72),
      (0.25, 85, 15, 109),
      (0.38, 136, 34, 106),
      (0.5, 186, 54, 85),
      (0.63, 227, 89, 51),
      (0.75, 249, 140, 10),
      (0.88, 252, 195, 65),
      (1.0, 252, 255, 164),
    ];

    for (var index = 1; index < palette.length; index += 1) {
      final lower = palette[index - 1];
      final upper = palette[index];
      if (value <= upper.$1) {
        final span = upper.$1 - lower.$1;
        final t = span == 0 ? 0.0 : (value - lower.$1) / span;
        return (
          _lerpChannel(lower.$2, upper.$2, t),
          _lerpChannel(lower.$3, upper.$3, t),
          _lerpChannel(lower.$4, upper.$4, t),
        );
      }
    }
    final last = palette.last;
    return (last.$2, last.$3, last.$4);
  }

  int _lerpChannel(int a, int b, double t) =>
      (a + ((b - a) * t)).round().clamp(0, 255);

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
