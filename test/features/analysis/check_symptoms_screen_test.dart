import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_flutter/app/app.dart';
import 'package:cloud_flutter/core/models/analysis_record.dart';
import 'package:cloud_flutter/core/models/condition_probability.dart';
import 'package:cloud_flutter/core/storage/local_storage_service.dart';
import 'package:cloud_flutter/features/analysis/data/analysis_inference_backend.dart';
import 'package:cloud_flutter/features/analysis/data/audio_capture_service.dart';
import 'package:cloud_flutter/features/analysis/data/cough_analysis_service.dart';
import 'package:cloud_flutter/features/analysis/data/spectrogram_export_service.dart';
import 'package:cloud_flutter/features/analysis/presentation/check_symptoms_screen.dart';
import 'package:cloud_flutter/features/result/presentation/result_screen.dart';

import '../../test_helpers/fake_local_storage_service.dart';

Widget _buildCheckSymptomsHarness(
  FakeLocalStorageService storage, {
  String initialLocation = '/check-symptoms',
  AudioCaptureService? audioCaptureService,
  CoughAnalysisService? coughAnalysisService,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/check-symptoms',
        builder: (_, __) => const CheckSymptomsScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Center(child: Text('Home'))),
      ),
      GoRoute(path: '/result', builder: (_, __) => const ResultScreen()),
      GoRoute(
        path: '/hospitals',
        builder:
            (_, __) => const Scaffold(body: Center(child: Text('Hospitals'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      localStorageServiceProvider.overrideWithValue(storage),
      audioCaptureServiceProvider.overrideWithValue(
        audioCaptureService ?? _buildAudioCaptureService(),
      ),
      coughAnalysisServiceProvider.overrideWithValue(
        coughAnalysisService ?? _buildAnalysisService(),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Finder _recordButton() => find.byType(FilledButton).first;

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('shows parity subtitle and AI classification info copy', (
    tester,
  ) async {
    final storage = FakeLocalStorageService();
    _setPhoneViewport(tester);

    await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
    await tester.pumpAndSettle();

    expect(find.text('Analyze your cough using AI'), findsOneWidget);
    expect(
      find.text('This tool analyzes cough patterns using AI classification'),
      findsOneWidget,
    );
    expect(find.text('⚠️ Not a medical diagnosis'), findsOneWidget);
  });

  testWidgets('shows an error when microphone permission is denied', (
    tester,
  ) async {
    final storage = FakeLocalStorageService();
    _setPhoneViewport(tester);

    await tester.pumpWidget(
      _buildCheckSymptomsHarness(
        storage,
        audioCaptureService: _buildAudioCaptureService(hasPermission: false),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_recordButton());
    await tester.pumpAndSettle();

    expect(
      find.text('Microphone permission is required to record your cough.'),
      findsOneWidget,
    );
    expect(find.text('Recording...'), findsNothing);
  });

  testWidgets(
    'tapping record again stops recording early and marks it recorded',
    (tester) async {
      final storage = FakeLocalStorageService();
      _setPhoneViewport(tester);

      await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
      await tester.pumpAndSettle();

      final recordButton = _recordButton();

      await tester.tap(recordButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(recordButton);
      await tester.pumpAndSettle();

      expect(find.text('Cough recorded ✓'), findsOneWidget);
      expect(find.text('Click analyze to continue'), findsOneWidget);
      expect(find.text('Recording...'), findsNothing);
    },
  );

  testWidgets('disables Analyze Now before a recording exists', (tester) async {
    final storage = FakeLocalStorageService();
    _setPhoneViewport(tester);

    await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Analyze Now'),
    );

    expect(button.onPressed, isNull);
    expect(find.text('⚠️ Please record your cough first'), findsNothing);
  });

  testWidgets(
    'analyze after recording stores the latest analysis and history',
    (tester) async {
      final storage = FakeLocalStorageService();
      _setPhoneViewport(tester);
      storage.hasCompletedOnboarding = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(storage),
            audioCaptureServiceProvider.overrideWithValue(
              _buildAudioCaptureService(),
            ),
            coughAnalysisServiceProvider.overrideWithValue(
              _buildAnalysisService(
                labels: const ['Bronchitis', 'Healthy'],
                scores: const [0.72, 0.28],
              ),
            ),
          ],
          child: const OhokApp(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Check Symptoms'));
      await tester.pumpAndSettle();

      await tester.tap(_recordButton());
      await tester.pump();
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Analyze Now'));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(find.text('Analysis Result'), findsOneWidget);
      expect(find.text('Bronchitis'), findsWidgets);
      expect(storage.history, isNotEmpty);
      expect(storage.history.first['condition'], 'Bronchitis');
      expect(storage.history.first['percentage'], 72);
    },
  );

  testWidgets('stops recording cleanly when leaving the screen', (
    tester,
  ) async {
    final storage = FakeLocalStorageService();
    _setPhoneViewport(tester);

    await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(_recordButton());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);

    await tester.pump(const Duration(seconds: 11));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ignores repeated Analyze Now taps after recording', (
    tester,
  ) async {
    final storage = FakeLocalStorageService();
    _setPhoneViewport(tester);

    await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(_recordButton());
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analyze Now'));
    await tester.tap(find.text('Analyze Now'));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(storage.history, hasLength(1));
    expect(find.text('Analysis Result'), findsOneWidget);
  });

  testWidgets('disables Analyze Now while recording is in progress', (
    tester,
  ) async {
    final storage = FakeLocalStorageService();
    _setPhoneViewport(tester);

    await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(_recordButton());
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Analyze Now'),
    );

    expect(button.onPressed, isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets(
    'shows recording progress and ends in a recorded state after 10 seconds',
    (tester) async {
      final storage = FakeLocalStorageService();
      _setPhoneViewport(tester);

      await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
      await tester.pumpAndSettle();

      await tester.tap(_recordButton());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('00:01'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      expect(find.text('Cough recorded ✓'), findsOneWidget);
      expect(find.text('00:01'), findsNothing);
    },
  );

  testWidgets('shows Analyzing state before navigating to result', (
    tester,
  ) async {
    final storage = FakeLocalStorageService();
    _setPhoneViewport(tester);

    await tester.pumpWidget(
      _buildCheckSymptomsHarness(
        storage,
        coughAnalysisService: _buildAnalysisService(
          onInfer: ({
            required input,
            required height,
            required width,
            required channels,
          }) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return const [0.72, 0.28];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_recordButton());
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analyze Now'));
    await tester.pump();

    expect(find.text('Analyzing...'), findsOneWidget);
    expect(find.text('Analysis Result'), findsNothing);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'shows success state as soon as analysis completes and waits 1 second before navigating to result',
    (
    tester,
  ) async {
    final storage = FakeLocalStorageService();
    _setPhoneViewport(tester);

    await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(_recordButton());
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analyze Now'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Analysis Complete ✓'), findsOneWidget);
    expect(find.text('Analysis Result'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Analysis Result'), findsOneWidget);
  },
  );

  testWidgets('disables recording during success delay before navigation', (
    tester,
  ) async {
    final storage = FakeLocalStorageService();
    _setPhoneViewport(tester);

    await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(_recordButton());
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analyze Now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();

    expect(find.text('Analysis Complete ✓'), findsOneWidget);

    final recordButton = tester.widget<FilledButton>(_recordButton());
    expect(recordButton.onPressed, isNull);

    await tester.tap(_recordButton());
    await tester.pump();

    expect(find.text('Recording...'), findsNothing);
    expect(find.text('00:01'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Analysis Result'), findsOneWidget);
  });

  testWidgets('result screen shows real probabilities and both CTAs navigate', (
    tester,
  ) async {
    final storage =
        FakeLocalStorageService()..history = [_persistedResult().toJson()];
    _setPhoneViewport(tester);

    await tester.pumpWidget(
      _buildCheckSymptomsHarness(storage, initialLocation: '/result'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analysis Result'), findsOneWidget);
    expect(find.text('Pneumonia'), findsWidgets);
    expect(find.text('COVID-19'), findsOneWidget);
    expect(find.text('Healthy'), findsOneWidget);

    final hospitalCta = find.widgetWithText(
      FilledButton,
      'Find Nearby Hospital',
    );
    await tester.ensureVisible(hospitalCta);
    await tester.pumpAndSettle();
    await tester.tap(hospitalCta);
    await tester.pumpAndSettle();
    expect(find.text('Hospitals'), findsOneWidget);

    await tester.pumpWidget(
      _buildCheckSymptomsHarness(storage, initialLocation: '/result'),
    );
    await tester.pumpAndSettle();

    final homeCta = find.widgetWithText(FilledButton, 'Back to Home');
    await tester.ensureVisible(homeCta);
    await tester.pumpAndSettle();
    await tester.tap(homeCta);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('stops analysis cleanly when leaving the screen', (tester) async {
    final storage = FakeLocalStorageService();
    _setPhoneViewport(tester);

    await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(_recordButton());
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analyze Now'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows error and stays on screen when history save fails, then allows retry',
    (tester) async {
      final storage =
          FakeLocalStorageService()
            ..historySaveException = Exception('disk full');
      _setPhoneViewport(tester);

      await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
      await tester.pumpAndSettle();

      await tester.tap(_recordButton());
      await tester.pump();
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();
      expect(find.text('Cough recorded ✓'), findsOneWidget);

      await tester.tap(find.text('Analyze Now'));
      await tester.pump(const Duration(seconds: 3));
      tester.takeException();
      await tester.pump();

      expect(find.text('Analyze Now'), findsOneWidget);
      expect(find.text('Analysis Result'), findsNothing);
      expect(
        find.text('Failed to analyze cough. Please try again.'),
        findsOneWidget,
      );
      expect(storage.history, isEmpty);

      storage.historySaveException = null;
      await tester.tap(find.text('Analyze Now'));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(find.text('Analysis Result'), findsOneWidget);
      expect(storage.history, isNotEmpty);
    },
  );
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
  Future<List<double>> Function({
    required Float32List input,
    required int height,
    required int width,
    required int channels,
  })? onInfer,
}) {
  return CoughAnalysisService(
    backend: _FakeAnalysisInferenceBackend(
      onInfer:
          onInfer ??
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

AnalysisRecord _persistedResult() {
  return AnalysisRecord(
    id: 'persisted-analysis',
    date: DateTime.utc(2025, 1, 2),
    condition: 'Pneumonia',
    percentage: 81,
    probabilities: const [
      ConditionProbability(
        name: 'Pneumonia',
        percentage: 81,
        hexColor: 0xFFEF4444,
      ),
      ConditionProbability(
        name: 'COVID-19',
        percentage: 12,
        hexColor: 0xFFEF4444,
      ),
      ConditionProbability(
        name: 'Healthy',
        percentage: 7,
        hexColor: 0xFF22C55E,
      ),
    ],
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
