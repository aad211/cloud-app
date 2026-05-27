import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_app/core/models/analysis_record.dart';
import 'package:cloud_app/core/models/condition_probability.dart';
import 'package:cloud_app/core/storage/local_storage_service.dart';
import 'package:cloud_app/features/analysis/presentation/latest_analysis_provider.dart';
import 'package:cloud_app/features/result/presentation/result_screen.dart';
import 'package:cloud_app/features/result/presentation/result_summary.dart';

import '../../test_helpers/fake_local_storage_service.dart';

Widget _buildHarness({
  AnalysisRecord? latestRecord,
  FakeLocalStorageService? storage,
}) {
  final fakeStorage = storage ?? FakeLocalStorageService();
  final router = GoRouter(
    initialLocation: '/result',
    routes: [
      GoRoute(path: '/result', builder: (_, __) => const ResultScreen()),
      GoRoute(
        path: '/home',
        builder:
            (_, __) =>
                const Scaffold(body: Center(child: Text('Home Destination'))),
      ),
      GoRoute(
        path: '/hospitals',
        builder:
            (_, __) => const Scaffold(
              body: Center(child: Text('Hospitals Destination')),
            ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      localStorageServiceProvider.overrideWithValue(fakeStorage),
      if (latestRecord != null)
        latestAnalysisProvider.overrideWith((ref) => latestRecord),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('renders the latest real analysis content', (tester) async {
    await tester.pumpWidget(_buildHarness(latestRecord: _latestRecord()));
    await tester.pumpAndSettle();

    expect(find.text('Analysis Result'), findsOneWidget);
    expect(find.text('Based on your cough recording'), findsOneWidget);
    expect(find.text('Bronchitis'), findsWidgets);
    expect(find.text('72%'), findsNWidgets(2));
    expect(find.text('Probability Breakdown'), findsOneWidget);
    expect(find.text('Healthy'), findsOneWidget);
    expect(find.text('What you should do'), findsOneWidget);
    expect(find.text('Consult a doctor if symptoms persist'), findsOneWidget);
    expect(find.text('Find Nearby Hospital'), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);
    expect(
      find.text(
        '⚠️ This is not a medical diagnosis. Please consult a healthcare professional.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'falls back to persisted history when no latest analysis exists',
    (tester) async {
      final storage =
          FakeLocalStorageService()..history = [_historyRecord().toJson()];

      await tester.pumpWidget(_buildHarness(storage: storage));
      await tester.pumpAndSettle();

      expect(find.text('Pneumonia'), findsWidgets);
      expect(find.text('81%'), findsNWidgets(2));
      expect(find.text('COVID-19'), findsOneWidget);
    },
  );

  testWidgets('shows the empty state when no analysis is available', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    expect(find.text('No analysis available yet.'), findsOneWidget);
    expect(find.text('Bronchitis'), findsNothing);
    expect(find.text('65%'), findsNothing);
  });

  test('buildResultSummary requires a real analysis record', () {
    expect(
      () => buildResultSummary(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'No analysis record available.',
        ),
      ),
    );
  });

  testWidgets('routes home from Back to Home CTA and hospitals from CTA', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness(latestRecord: _latestRecord()));
    await tester.pumpAndSettle();

    final homeCta = find.widgetWithText(FilledButton, 'Back to Home');
    await tester.ensureVisible(homeCta);
    await tester.pumpAndSettle();
    await tester.tap(homeCta);
    await tester.pumpAndSettle();
    expect(find.text('Home Destination'), findsOneWidget);

    await tester.pumpWidget(_buildHarness(latestRecord: _latestRecord()));
    await tester.pumpAndSettle();

    final hospitalCta = find.widgetWithText(
      FilledButton,
      'Find Nearby Hospital',
    );
    await tester.ensureVisible(hospitalCta);
    await tester.pumpAndSettle();
    await tester.tap(hospitalCta);
    await tester.pumpAndSettle();
    expect(find.text('Hospitals Destination'), findsOneWidget);
  });

  testWidgets('accepts optional recordId parameter', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: ResultScreen(recordId: 'test-id')),
      ),
    );

    // Should build without error
    expect(find.byType(ResultScreen), findsOneWidget);
  });

  testWidgets('shows historical record when recordId matches', (tester) async {
    final historyRecord = AnalysisRecord(
      id: 'historical-123',
      date: DateTime(2026, 5, 20, 10, 0),
      condition: 'Bronchitis',
      percentage: 75,
      probabilities: const [
        ConditionProbability(
          name: 'Bronchitis',
          percentage: 75,
          hexColor: 0xFFFAB95B,
        ),
        ConditionProbability(
          name: 'Healthy',
          percentage: 25,
          hexColor: 0xFF22C55E,
        ),
      ],
    );

    final storage =
        FakeLocalStorageService()..history = [historyRecord.toJson()];

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => ResultScreen(recordId: 'historical-123'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bronchitis'), findsWidgets);
    expect(find.text('75%'), findsNWidgets(2));
  });

  testWidgets('shows historical header when viewing historical record', (
    tester,
  ) async {
    final historyRecord = AnalysisRecord(
      id: 'historical-123',
      date: DateTime(2026, 5, 20, 10, 0),
      condition: 'Healthy',
      percentage: 85,
      probabilities: const [
        ConditionProbability(
          name: 'Healthy',
          percentage: 85,
          hexColor: 0xFF22C55E,
        ),
        ConditionProbability(
          name: 'Bronchitis',
          percentage: 15,
          hexColor: 0xFFFAB95B,
        ),
      ],
    );

    final storage =
        FakeLocalStorageService()..history = [historyRecord.toJson()];

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => ResultScreen(recordId: 'historical-123'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Historical Record'), findsOneWidget);
    expect(find.text('Recorded on May 20, 2026'), findsOneWidget);
  });

  testWidgets('shows fresh analysis header when no recordId', (tester) async {
    final freshRecord = AnalysisRecord(
      id: 'fresh-123',
      date: DateTime.now(),
      condition: 'Healthy',
      percentage: 90,
      probabilities: const [
        ConditionProbability(
          name: 'Healthy',
          percentage: 90,
          hexColor: 0xFF22C55E,
        ),
        ConditionProbability(
          name: 'Bronchitis',
          percentage: 10,
          hexColor: 0xFFFAB95B,
        ),
      ],
    );

    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, __) => const ResultScreen())],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [latestAnalysisProvider.overrideWith((ref) => freshRecord)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Analysis Result'), findsOneWidget);
    expect(find.text('Based on your cough recording'), findsOneWidget);
  });

  testWidgets(
    'back button navigates to history when viewing historical record',
    (tester) async {
      final historyRecord = AnalysisRecord(
        id: 'historical-123',
        date: DateTime(2026, 5, 20),
        condition: 'Healthy',
        percentage: 85,
        probabilities: const [
          ConditionProbability(
            name: 'Healthy',
            percentage: 85,
            hexColor: 0xFF22C55E,
          ),
          ConditionProbability(
            name: 'Bronchitis',
            percentage: 15,
            hexColor: 0xFFFAB95B,
          ),
        ],
      );

      final storage =
          FakeLocalStorageService()..history = [historyRecord.toJson()];

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => ResultScreen(recordId: 'historical-123'),
          ),
          GoRoute(
            path: '/history',
            builder: (_, __) => const Scaffold(body: Text('History')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [localStorageServiceProvider.overrideWithValue(storage)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);
    },
  );

  testWidgets('system back gesture pops to history from historical result', (
    tester,
  ) async {
    final historyRecord = AnalysisRecord(
      id: 'historical-123',
      date: DateTime(2026, 5, 20),
      condition: 'Healthy',
      percentage: 85,
      probabilities: const [
        ConditionProbability(
          name: 'Healthy',
          percentage: 85,
          hexColor: 0xFF22C55E,
        ),
        ConditionProbability(
          name: 'Bronchitis',
          percentage: 15,
          hexColor: 0xFFFAB95B,
        ),
      ],
    );

    final storage =
        FakeLocalStorageService()..history = [historyRecord.toJson()];

    final router = GoRouter(
      initialLocation: '/history',
      routes: [
        GoRoute(
          path: '/history',
          builder:
              (context, state) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed:
                        () => context.push('/result?recordId=historical-123'),
                    child: const Text('Open Result'),
                  ),
                ),
              ),
        ),
        GoRoute(
          path: '/result',
          builder: (context, state) {
            final recordId = state.uri.queryParameters['recordId'];
            return ResultScreen(recordId: recordId);
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Result'));
    await tester.pumpAndSettle();

    expect(find.text('Historical Record'), findsOneWidget);

    final didPop = await router.routerDelegate.popRoute();
    expect(didPop, isTrue);
    await tester.pumpAndSettle();

    expect(find.text('Open Result'), findsOneWidget);
  });

  testWidgets('back button navigates to home when viewing fresh analysis', (
    tester,
  ) async {
    final freshRecord = AnalysisRecord(
      id: 'fresh-123',
      date: DateTime.now(),
      condition: 'Healthy',
      percentage: 90,
      probabilities: const [
        ConditionProbability(
          name: 'Healthy',
          percentage: 90,
          hexColor: 0xFF22C55E,
        ),
        ConditionProbability(
          name: 'Bronchitis',
          percentage: 10,
          hexColor: 0xFFFAB95B,
        ),
      ],
    );

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const ResultScreen()),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [latestAnalysisProvider.overrideWith((ref) => freshRecord)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}

AnalysisRecord _latestRecord() {
  return AnalysisRecord(
    id: 'latest-analysis',
    date: DateTime.utc(2025, 1, 1),
    condition: 'Bronchitis',
    percentage: 72,
    probabilities: const [
      ConditionProbability(
        name: 'Bronchitis',
        percentage: 72,
        hexColor: 0xFFFAB95B,
      ),
      ConditionProbability(
        name: 'Healthy',
        percentage: 28,
        hexColor: 0xFF22C55E,
      ),
    ],
  );
}

AnalysisRecord _historyRecord() {
  return AnalysisRecord(
    id: 'history-analysis',
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
        percentage: 19,
        hexColor: 0xFFEF4444,
      ),
    ],
  );
}
