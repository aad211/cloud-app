import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_app/features/analysis/data/analysis_inference_backend.dart';
import 'package:cloud_app/features/analysis/data/cough_analysis_service.dart';
import 'package:cloud_app/features/analysis/data/spectrogram_export_service.dart';
import 'package:cloud_app/features/analysis/domain/recorded_cough.dart';

void main() {
  test(
    'analyze builds an AnalysisRecord from labels, backend scores, and export results',
    () async {
      final wavBytes = _buildTestWav(samples: const [0, 8192, -8192, 16384]);
      final recordedCough = RecordedCough(
        reference: '/records/cough.wav',
        wavBytes: wavBytes,
        backend: RecordedCoughBackend.nativeFile,
      );
      final observed = _ObservedCalls();
      final backend = _FakeAnalysisInferenceBackend(
        onInfer: ({
          required input,
          required height,
          required width,
          required channels,
        }) async {
          observed.backendInput = input;
          observed.height = height;
          observed.width = width;
          observed.channels = channels;
          return const [0.1, 0.75, 0.15];
        },
      );

      final service = CoughAnalysisService(
        backend: backend,
        loadLabels: () async => const ['Healthy', 'Bronchitis', 'Pneumonia'],
        readWavSamples: (bytes) {
          observed.readBytes = bytes;
          return const [0.0, 0.25, -0.25, 0.5];
        },
        computeMelSpectrogram: (samples) {
          observed.samples = samples;
          return const [
            [10.0, 20.0, 30.0],
            [40.0, 50.0, 60.0],
          ];
        },
        exportSpectrogram: ({
          required analysisId,
          required melSpectrogram,
        }) async {
          observed.exportAnalysisId = analysisId;
          observed.exportMel = melSpectrogram;
          return const SpectrogramExportResult(
            spectrogramFilePath: '/exports/analysis-123.png',
            storageBackend: 'native',
            repoMirrorPath: '/repo/analysis-123.png',
          );
        },
        generateId: () => 'analysis-123',
        now: () => DateTime.utc(2025, 1, 2, 3, 4, 5),
        inputHeight: 2,
        inputWidth: 3,
        inputChannels: 1,
      );

      final record = await service.analyze(recordedCough);

      expect(observed.readBytes, wavBytes);
      expect(observed.samples, const [0.0, 0.25, -0.25, 0.5]);
      expect(observed.exportAnalysisId, 'analysis-123');
      expect(observed.exportMel, const [
        [10.0, 20.0, 30.0],
        [40.0, 50.0, 60.0],
      ]);
      // The backend returns [128, 128, 1] as expected shape (from mock),
      // so the service uses those dimensions instead of constructor params
      expect(observed.height, 128);
      expect(observed.width, 128);
      expect(observed.channels, 1);
      expect(observed.backendInput, hasLength(128 * 128 * 1));
      // Check first and last values are normalized correctly
      expect(observed.backendInput![0], closeTo(0.0, 0.0001));
      expect(observed.backendInput![128 * 128 - 1], closeTo(1.0, 0.0001));

      expect(record.id, 'analysis-123');
      expect(record.date, DateTime.utc(2025, 1, 2, 3, 4, 5));
      expect(record.condition, 'Bronchitis');
      expect(record.percentage, 75);
      expect(record.audioFilePath, isNull);
      expect(record.spectrogramFilePath, '/exports/analysis-123.png');
      expect(record.repoMirrorPath, '/repo/analysis-123.png');
      expect(record.storageBackend, 'native');
      expect(record.probabilities.map((item) => item.name).toList(), [
        'Bronchitis',
        'Pneumonia',
        'Healthy',
      ]);
      expect(record.probabilities.map((item) => item.percentage).toList(), [
        75,
        15,
        10,
      ]);
    },
  );

  test('analyze throws when labels are empty', () async {
    final service = _buildService(
      loadLabels: () async => const [],
      backendScores: const [1.0],
    );

    await expectLater(
      () => service.analyze(_recordedCough()),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'No analysis labels were loaded from assets/labels.txt.',
        ),
      ),
    );
  });

  test('analyze throws when backend returns no scores', () async {
    final service = _buildService(
      loadLabels: () async => const ['Healthy'],
      backendScores: const [],
    );

    await expectLater(
      () => service.analyze(_recordedCough()),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Inference backend returned no scores.',
        ),
      ),
    );
  });

  test('analyze throws when label and score counts differ', () async {
    final service = _buildService(
      loadLabels: () async => const ['Healthy', 'Bronchitis'],
      backendScores: const [1.0],
    );

    await expectLater(
      () => service.analyze(_recordedCough()),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Expected 2 scores for the loaded labels, but received 1.',
        ),
      ),
    );
  });

  test('analyze rejects recordings that do not decode into WAV samples', () async {
    final service = CoughAnalysisService(
      backend: _FakeAnalysisInferenceBackend(
        onInfer: ({
          required input,
          required height,
          required width,
          required channels,
        }) async {
          fail('infer should not run when WAV decoding fails');
        },
      ),
      loadLabels: () async => const ['Healthy'],
      exportSpectrogram: ({
        required analysisId,
        required melSpectrogram,
      }) async {
        fail('spectrogram export should not run when WAV decoding fails');
      },
      generateId: () => 'analysis-invalid-wav',
      now: () => DateTime.utc(2025, 1, 1),
      inputHeight: 1,
      inputWidth: 1,
      inputChannels: 1,
    );

    await expectLater(
      () => service.analyze(
        RecordedCough(
          reference: 'blob:http://localhost/invalid',
          wavBytes: Uint8List.fromList(const [0, 1, 2, 3]),
          backend: RecordedCoughBackend.webBlob,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Recorded cough audio did not contain valid 16-bit PCM WAV samples.',
        ),
      ),
    );
  });
}

class _FakeAnalysisInferenceBackend implements AnalysisInferenceBackend {
  const _FakeAnalysisInferenceBackend({required this.onInfer});

  final Future<List<double>> Function({
    required Float32List input,
    required int height,
    required int width,
    required int channels,
  })
  onInfer;

  @override
  Future<List<int>> getExpectedInputShape() async => const [128, 128, 1];

  @override
  Future<List<double>> infer({
    required Float32List input,
    required int height,
    required int width,
    required int channels,
  }) {
    return onInfer(
      input: input,
      height: height,
      width: width,
      channels: channels,
    );
  }
}

class _ObservedCalls {
  Uint8List? readBytes;
  List<double>? samples;
  Float32List? backendInput;
  int? height;
  int? width;
  int? channels;
  String? exportAnalysisId;
  List<List<double>>? exportMel;
}

CoughAnalysisService _buildService({
  required Future<List<String>> Function() loadLabels,
  required List<double> backendScores,
}) {
  return CoughAnalysisService(
    backend: _FakeAnalysisInferenceBackend(
      onInfer:
          ({
            required input,
            required height,
            required width,
            required channels,
          }) async => backendScores,
    ),
    loadLabels: loadLabels,
    readWavSamples: (_) => const [0.0],
    computeMelSpectrogram:
        (_) => const [
          [0.0],
        ],
    exportSpectrogram:
        ({required analysisId, required melSpectrogram}) async =>
            const SpectrogramExportResult(
              spectrogramFilePath: 'spectrogram.png',
              storageBackend: 'native',
            ),
    generateId: () => 'analysis-test',
    now: () => DateTime.utc(2025, 1, 1),
    inputHeight: 1,
    inputWidth: 1,
    inputChannels: 1,
  );
}

RecordedCough _recordedCough() {
  return RecordedCough(
    reference: '/records/cough.wav',
    wavBytes: _buildTestWav(samples: const [0]),
    backend: RecordedCoughBackend.nativeFile,
  );
}

Uint8List _le16(int value) {
  final data = ByteData(2)..setInt16(0, value, Endian.little);
  return data.buffer.asUint8List();
}

Uint8List _le32(int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.little);
  return data.buffer.asUint8List();
}

Uint8List _buildTestWav({required List<int> samples}) {
  final sampleBytes = BytesBuilder();
  for (final sample in samples) {
    sampleBytes.add(_le16(sample));
  }

  final formatChunk = Uint8List.fromList([
    ...'fmt '.codeUnits,
    ..._le32(16),
    ..._le16(1),
    ..._le16(1),
    ..._le32(16000),
    ..._le32(32000),
    ..._le16(2),
    ..._le16(16),
  ]);
  final dataChunk = Uint8List.fromList([
    ...'data'.codeUnits,
    ..._le32(sampleBytes.length),
    ...sampleBytes.toBytes(),
  ]);
  final riffBody = Uint8List.fromList([
    ...'WAVE'.codeUnits,
    ...formatChunk,
    ...dataChunk,
  ]);

  return Uint8List.fromList([
    ...'RIFF'.codeUnits,
    ..._le32(riffBody.length),
    ...riffBody,
  ]);
}
