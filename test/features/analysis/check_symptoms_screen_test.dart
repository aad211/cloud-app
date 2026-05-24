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

void main() {
  testWidgets('analyze requires recording and saves a mocked result',
      (tester) async {
    final storage = FakeLocalStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
        child: const OhokApp(),
      ),
    );

    storage.hasCompletedOnboarding = true;
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check Symptoms'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analyze Now'));
    await tester.pumpAndSettle();
    expect(find.text('Please record your cough first'), findsOneWidget);

    await tester.tap(find.text('Tap to record your cough'));
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analyze Now'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Analysis Result'), findsOneWidget);
    expect(storage.history, isNotEmpty);
  });

  testWidgets('stops mock recording cleanly when leaving the screen',
      (tester) async {
    final storage = FakeLocalStorageService();

    await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap to record your cough'));
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

    await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap to record your cough'));
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analyze Now'));
    await tester.tap(find.text('Analyze Now'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(storage.history, hasLength(1));
    expect(find.text('Analysis Result'), findsOneWidget);
  });

  testWidgets('disables Analyze Now while recording is in progress',
      (tester) async {
    final storage = FakeLocalStorageService();

    await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap to record your cough'));
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

    await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap to record your cough'));
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

    await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap to record your cough'));
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analyze Now'));
    await tester.pump();

    expect(find.text('Analyzing...'), findsOneWidget);
    expect(find.text('Analysis Result'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('result screen shows mocked probabilities and both CTAs navigate',
      (tester) async {
    final storage = FakeLocalStorageService();

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

    await tester.tap(find.text('Find Nearby Hospital'));
    await tester.pumpAndSettle();
    expect(find.text('Hospitals'), findsOneWidget);

    await tester.pumpWidget(
      _buildCheckSymptomsHarness(storage, initialLocation: '/result'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('stops analysis cleanly when leaving the screen',
      (tester) async {
    final storage = FakeLocalStorageService();

    await tester.pumpWidget(_buildCheckSymptomsHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap to record your cough'));
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
}
