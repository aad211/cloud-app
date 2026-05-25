import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/app/app.dart';
import 'package:ohok_flutter/core/storage/local_storage_service.dart';
import 'package:ohok_flutter/features/analysis/presentation/check_symptoms_screen.dart';
import 'package:ohok_flutter/features/result/presentation/result_screen.dart';
import '../../test_helpers/fake_local_storage_service.dart';

Widget _buildCheckSymptomsHarness(
  FakeLocalStorageService storage, {
  String initialLocation = '/check-symptoms',
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
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Home'))),
      ),
      GoRoute(
        path: '/result',
        builder: (_, __) => const ResultScreen(),
      ),
      GoRoute(
        path: '/hospitals',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Hospitals'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [localStorageServiceProvider.overrideWithValue(storage)],
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
  testWidgets('shows parity subtitle and AI classification info copy',
      (tester) async {
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

  testWidgets('tapping record again stops recording early and marks it recorded',
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
  });

  testWidgets('missing-recording error clears after 3 seconds', (tester) async {
    final storage = FakeLocalStorageService();
    _setPhoneViewport(tester);

    await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analyze Now'));
    await tester.pump();

    expect(find.text('⚠️ Please record your cough first'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('⚠️ Please record your cough first'), findsNothing);
  });

  testWidgets('analyze requires recording and saves a mocked result',
      (tester) async {
    final storage = FakeLocalStorageService();
    _setPhoneViewport(tester);
    storage.hasCompletedOnboarding = true; // must be set before guard init

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
        child: const OhokApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check Symptoms'));
    await tester.pumpAndSettle();

     await tester.tap(find.text('Analyze Now'));
     await tester.pumpAndSettle();
    expect(find.text('⚠️ Please record your cough first'), findsOneWidget);

    await tester.tap(_recordButton());
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analyze Now'));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Analysis Result'), findsOneWidget);
    expect(storage.history, isNotEmpty);
  });

  testWidgets('stops mock recording cleanly when leaving the screen',
      (tester) async {
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

  testWidgets('ignores repeated Analyze Now taps after recording',
      (tester) async {
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

  testWidgets('disables Analyze Now while recording is in progress',
      (tester) async {
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
  });

  testWidgets('shows Analyzing state before navigating to result',
      (tester) async {
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

    expect(find.text('Analyzing...'), findsOneWidget);
    expect(find.text('Analysis Result'), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('shows success state for 1 second before navigating to result',
      (tester) async {
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

    expect(find.text('Analyzing...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();

    expect(find.text('Analysis Complete ✓'), findsOneWidget);
    expect(find.text('Analysis Result'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Analysis Result'), findsOneWidget);
  });

  testWidgets('disables recording during success delay before navigation',
      (tester) async {
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

  testWidgets('result screen shows mocked probabilities and both CTAs navigate',
      (tester) async {
    final storage = FakeLocalStorageService();
    _setPhoneViewport(tester);

    await tester.pumpWidget(
      _buildCheckSymptomsHarness(storage, initialLocation: '/result'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analysis Result'), findsOneWidget);
    expect(find.text('Healthy'), findsOneWidget);
    expect(find.text('Asthma'), findsOneWidget);
    expect(find.text('Pneumonia'), findsOneWidget);
    expect(find.text('COVID-19'), findsOneWidget);
    expect(find.text('Lung Cancer'), findsOneWidget);

    final hospitalCta = find.widgetWithText(FilledButton, 'Find Nearby Hospital');
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

  testWidgets('stops analysis cleanly when leaving the screen',
      (tester) async {
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
      final storage = FakeLocalStorageService()
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
      // Consume the framework-level exception from the unhandled async error.
      // In GREEN (fixed code), analyze() catches it internally and calls
      // FlutterError.reportError, so the framework still stores one exception
      // here; takeException() clears it in both RED and GREEN so assertions
      // can proceed.
      tester.takeException();
      await tester.pump();

      // Should stay on the check-symptoms screen with an error message.
      expect(find.text('Analyze Now'), findsOneWidget);
      expect(find.text('Analysis Result'), findsNothing);
      expect(
        find.text('Failed to save analysis. Please try again.'),
        findsOneWidget,
      );
      expect(storage.history, isEmpty);

      // After clearing the exception, retrying should succeed.
      storage.historySaveException = null;
      await tester.tap(find.text('Analyze Now'));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(find.text('Analysis Result'), findsOneWidget);
      expect(storage.history, isNotEmpty);
    },
  );
}
