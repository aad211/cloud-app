import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_flutter/core/storage/local_storage_service.dart';
import 'package:cloud_flutter/features/analysis/data/analysis_inference_backend.dart';
import 'package:cloud_flutter/features/analysis/data/audio_capture_service.dart';
import 'package:cloud_flutter/features/analysis/data/cough_analysis_service.dart';
import 'package:cloud_flutter/features/analysis/data/spectrogram_export_service.dart';
import 'package:cloud_flutter/features/analysis/presentation/check_symptoms_controller.dart';
import 'package:cloud_flutter/features/analysis/presentation/latest_analysis_provider.dart';

import '../../test_helpers/fake_local_storage_service.dart';

void main() {
  test('toggleRecording ignores non-idle button states', () async {
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(
          FakeLocalStorageService(),
        ),
        audioCaptureServiceProvider.overrideWithValue(
          _buildAudioCaptureService(),
        ),
        coughAnalysisServiceProvider.overrideWithValue(_buildAnalysisService()),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      checkSymptomsControllerProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);

    final notifier = container.read(checkSymptomsControllerProvider.notifier);
    notifier.state = notifier.state.copyWith(
      buttonState: AnalysisButtonState.success,
    );

    await notifier.toggleRecording();

    expect(notifier.state.buttonState, AnalysisButtonState.success);
    expect(notifier.state.isRecording, isFalse);
    expect(notifier.state.recordingTime, 0);
    expect(notifier.state.hasRecording, isFalse);
  });

  test(
    'toggleRecording shows an error when microphone permission is denied',
    () async {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(
            FakeLocalStorageService(),
          ),
          audioCaptureServiceProvider.overrideWithValue(
            _buildAudioCaptureService(hasPermission: false),
          ),
          coughAnalysisServiceProvider.overrideWithValue(
            _buildAnalysisService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        checkSymptomsControllerProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);

      final notifier = container.read(checkSymptomsControllerProvider.notifier);

      await notifier.toggleRecording();

      expect(notifier.state.isRecording, isFalse);
      expect(notifier.state.hasRecording, isFalse);
      expect(
        notifier.state.errorMessage,
        'Microphone permission is required to record your cough.',
      );
    },
  );

  test(
    'successful analyze stores the latest analysis and persisted history',
    () async {
      final storage = FakeLocalStorageService();
      var startCount = 0;
      var stopCount = 0;
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          audioCaptureServiceProvider.overrideWithValue(
            _buildAudioCaptureService(
              onStart: ({required path}) async {
                startCount += 1;
              },
              onStop: () async {
                stopCount += 1;
                return '/records/cough.wav';
              },
            ),
          ),
          coughAnalysisServiceProvider.overrideWithValue(
            _buildAnalysisService(
              labels: const ['Bronchitis', 'Healthy'],
              scores: const [0.72, 0.28],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        checkSymptomsControllerProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);

      final notifier = container.read(checkSymptomsControllerProvider.notifier);

      await notifier.toggleRecording();
      await notifier.toggleRecording();

      expect(startCount, 1);
      expect(stopCount, 1);
      expect(notifier.state.hasRecording, isTrue);

      final success = await notifier.analyze();

      expect(success, isTrue);
      expect(notifier.state.buttonState, AnalysisButtonState.success);
      expect(container.read(latestAnalysisProvider)?.condition, 'Bronchitis');
      expect(container.read(latestAnalysisProvider)?.percentage, 72);
      expect(storage.history, hasLength(1));
      expect(storage.history.single['condition'], 'Bronchitis');
      expect(storage.history.single['percentage'], 72);
    },
  );

  test(
    'analyze maps missing model setup failures to a user-safe message',
    () async {
      final storage = FakeLocalStorageService();
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          audioCaptureServiceProvider.overrideWithValue(
            _buildAudioCaptureService(),
          ),
          coughAnalysisServiceProvider.overrideWithValue(
            CoughAnalysisService(
              backend: _FakeAnalysisInferenceBackend(
                onInfer: ({
                  required input,
                  required height,
                  required width,
                  required channels,
                }) async {
                  fail('infer should not run when labels are missing');
                },
              ),
              loadLabels: () async {
                throw StateError(
                  'Analysis labels are missing at assets/models/labels.txt. '
                  'Add and register the real labels.txt file before running analysis.',
                );
              },
              generateId: () => 'analysis-test',
              now: () => DateTime.utc(2025, 1, 1),
              inputHeight: 1,
              inputWidth: 1,
              inputChannels: 1,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        checkSymptomsControllerProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);

      final notifier = container.read(checkSymptomsControllerProvider.notifier);

      await notifier.toggleRecording();
      await notifier.toggleRecording();

      final success = await notifier.analyze();

      expect(success, isFalse);
      expect(notifier.state.buttonState, AnalysisButtonState.idle);
      expect(
        notifier.state.errorMessage,
        'Analysis setup is incomplete. Add the real model and labels before running analysis.',
      );
      expect(container.read(latestAnalysisProvider), isNull);
      expect(storage.history, isEmpty);
    },
  );

  test('analyze maps invalid WAV errors to a user-safe message', () async {
    final storage = FakeLocalStorageService();
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storage),
        audioCaptureServiceProvider.overrideWithValue(_buildAudioCaptureService()),
        coughAnalysisServiceProvider.overrideWithValue(
          CoughAnalysisService(
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
            readWavSamples: (_) => const [],
            generateId: () => 'analysis-test',
            now: () => DateTime.utc(2025, 1, 1),
            inputHeight: 1,
            inputWidth: 1,
            inputChannels: 1,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      checkSymptomsControllerProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);

    final notifier = container.read(checkSymptomsControllerProvider.notifier);

    await notifier.toggleRecording();
    await notifier.toggleRecording();

    final success = await notifier.analyze();

    expect(success, isFalse);
    expect(notifier.state.buttonState, AnalysisButtonState.idle);
    expect(
      notifier.state.errorMessage,
      'Recorded cough audio is invalid. Please try recording again.',
    );
    expect(storage.history, isEmpty);
  });
}

AudioCaptureService _buildAudioCaptureService({
  bool hasPermission = true,
  Future<void> Function({required String? path})? onStart,
  Future<String?> Function()? onStop,
}) {
  return AudioCaptureService(
    isWeb: true,
    hasPermissionCallback: () async => hasPermission,
    startCallback: onStart ?? ({required path}) async {},
    stopCallback: onStop ?? () async => '/records/cough.wav',
    readBlobBytes: (_) async => Uint8List.fromList(const [1, 2, 3]),
  );
}

CoughAnalysisService _buildAnalysisService({
  List<String> labels = const ['Bronchitis', 'Healthy'],
  List<double> scores = const [0.72, 0.28],
}) {
  return CoughAnalysisService(
    backend: _FakeAnalysisInferenceBackend(
      onInfer:
          ({
            required input,
            required height,
            required width,
            required channels,
          }) async => scores,
    ),
    loadLabels: () async => labels,
    readWavSamples: (_) => const [0.0],
    computeMelSpectrogram:
        (_) => const [
          [0.0],
        ],
    exportSpectrogram:
        ({required analysisId, required melSpectrogram}) async =>
            const SpectrogramExportResult(
              spectrogramFilePath: 'spectrogram.png',
              storageBackend: 'test',
            ),
    generateId: () => 'analysis-test',
    now: () => DateTime.utc(2025, 1, 1),
    inputHeight: 1,
    inputWidth: 1,
    inputChannels: 1,
  );
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
