import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_app/core/models/analysis_record.dart';
import 'package:cloud_app/core/storage/local_storage_service.dart';
import 'package:cloud_app/features/history/presentation/history_screen.dart';

import '../../test_helpers/fake_local_storage_service.dart';

Widget _buildHistory({
  required FakeLocalStorageService storage,
  DateTime? now,
}) {
  return ProviderScope(
    overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    child: MaterialApp(
      home: HistoryScreen(now: now),
    ),
  );
}

Widget _buildHistoryRouter({
  required FakeLocalStorageService storage,
  DateTime? now,
}) {
  final router = GoRouter(
    initialLocation: '/history',
    routes: [
      GoRoute(
        path: '/history',
        builder: (_, __) => ProviderScope(
          overrides: [localStorageServiceProvider.overrideWithValue(storage)],
          child: HistoryScreen(now: now),
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Home Destination'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('HistoryScreen – empty state', () {
    testWidgets('shows No History Yet when there are no records',
        (tester) async {
      final storage = FakeLocalStorageService();

      await tester.pumpWidget(_buildHistory(storage: storage));
      await tester.pump();

      expect(find.text('No History Yet'), findsOneWidget);
    });

    testWidgets('shows the React empty state visuals and copy', (tester) async {
      final storage = FakeLocalStorageService();

      await tester.pumpWidget(_buildHistory(storage: storage));
      await tester.pump();

      expect(find.text('📋'), findsOneWidget);
      expect(find.text('No History Yet'), findsOneWidget);
      expect(
        find.text(
          'Start checking your symptoms to build your health history',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows all three period filter chips', (tester) async {
      final storage = FakeLocalStorageService();

      await tester.pumpWidget(_buildHistory(storage: storage));
      await tester.pump();

      expect(find.text('All Time'), findsOneWidget);
      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
    });

    testWidgets('shows a distinct error state when history fails to load',
        (tester) async {
      final storage = FakeLocalStorageService()
        ..historyLoadException = Exception('load failed');

      await tester.pumpWidget(_buildHistory(storage: storage));
      await tester.pump();
      await tester.pump();

      expect(find.text('Unable to load history'), findsOneWidget);
      expect(find.text('No History Yet'), findsNothing);
    });
  });

  group('HistoryScreen – with records', () {
    FakeLocalStorageService storageWith(List<AnalysisRecord> records) {
      final storage = FakeLocalStorageService()
        ..history = records.map((r) => r.toJson()).toList();
      return storage;
    }

    testWidgets('shows condition name for each record', (tester) async {
      final storage = storageWith([
        AnalysisRecord(
          id: 'r1',
          date: DateTime(2025, 6, 15, 14, 30),
          condition: 'Asthma',
          percentage: 87,
        ),
      ]);

      await tester.pumpWidget(_buildHistory(storage: storage));
      await tester.pump();

      expect(find.text('Asthma'), findsOneWidget);
    });

    testWidgets('shows percentage for each record', (tester) async {
      final storage = storageWith([
        AnalysisRecord(
          id: 'r1',
          date: DateTime(2025, 6, 15, 14, 30),
          condition: 'Asthma',
          percentage: 87,
        ),
      ]);

      await tester.pumpWidget(_buildHistory(storage: storage));
      await tester.pump();

      expect(find.text('87%'), findsOneWidget);
    });

    testWidgets('shows time in hh:mm a format', (tester) async {
      final storage = storageWith([
        AnalysisRecord(
          id: 'r1',
          date: DateTime(2025, 6, 15, 14, 30),
          condition: 'Asthma',
          percentage: 87,
        ),
      ]);

      await tester.pumpWidget(_buildHistory(storage: storage));
      await tester.pump();

      expect(find.text('June 15, 2025, 02:30 PM'), findsOneWidget);
    });

    testWidgets('shows date group heading', (tester) async {
      final storage = storageWith([
        AnalysisRecord(
          id: 'r1',
          date: DateTime(2025, 6, 15, 14, 30),
          condition: 'Asthma',
          percentage: 87,
        ),
      ]);

      await tester.pumpWidget(_buildHistory(storage: storage));
      await tester.pump();

      expect(find.text('June 15, 2025'), findsOneWidget);
    });

    testWidgets('groups records under same heading when on same day',
        (tester) async {
      final storage = storageWith([
        AnalysisRecord(
          id: 'r1',
          date: DateTime(2025, 6, 15, 9, 0),
          condition: 'Asthma',
          percentage: 87,
        ),
        AnalysisRecord(
          id: 'r2',
          date: DateTime(2025, 6, 15, 15, 0),
          condition: 'Bronchitis',
          percentage: 65,
        ),
      ]);

      await tester.pumpWidget(_buildHistory(storage: storage));
      await tester.pump();

      // Only one date heading for both records
      expect(find.text('June 15, 2025'), findsOneWidget);
      expect(find.text('Asthma'), findsOneWidget);
      expect(find.text('Bronchitis'), findsOneWidget);
    });

    testWidgets('shows separate headings for different days', (tester) async {
      final storage = storageWith([
        AnalysisRecord(
          id: 'r1',
          date: DateTime(2025, 6, 15, 9, 0),
          condition: 'Asthma',
          percentage: 87,
        ),
        AnalysisRecord(
          id: 'r2',
          date: DateTime(2025, 6, 16, 10, 0),
          condition: 'Bronchitis',
          percentage: 65,
        ),
      ]);

      await tester.pumpWidget(_buildHistory(storage: storage));
      await tester.pump();

      expect(find.text('June 15, 2025'), findsOneWidget);
      expect(find.text('June 16, 2025'), findsOneWidget);
    });

    testWidgets('renders date groups newest first even when input is unsorted',
        (tester) async {
      final storage = storageWith([
        AnalysisRecord(
          id: 'older',
          date: DateTime(2025, 6, 15, 9, 0),
          condition: 'Asthma',
          percentage: 87,
        ),
        AnalysisRecord(
          id: 'newer',
          date: DateTime(2025, 6, 16, 10, 0),
          condition: 'Bronchitis',
          percentage: 65,
        ),
      ]);

      await tester.pumpWidget(_buildHistory(storage: storage));
      await tester.pump();

      final newerHeading = tester.getTopLeft(find.text('June 16, 2025'));
      final olderHeading = tester.getTopLeft(find.text('June 15, 2025'));

      expect(newerHeading.dy, lessThan(olderHeading.dy));
    });

    testWidgets('renders the React parity subtitle, cards, insights and disclaimer',
        (tester) async {
      final storage = storageWith([
        AnalysisRecord(
          id: 'r1',
          date: DateTime(2025, 6, 15, 14, 30),
          condition: 'Asthma',
          percentage: 87,
        ),
      ]);

      await tester.pumpWidget(_buildHistory(storage: storage));
      await tester.pump();

      expect(
        find.text('Track your respiratory health over time'),
        findsOneWidget,
      );
      expect(find.text('All Records (1)'), findsOneWidget);
      expect(find.text('🫁'), findsOneWidget);
      expect(find.text('💡 Health Insights'), findsOneWidget);
      expect(
        find.text(
          '⚠️ This is not a medical diagnosis. Please consult a healthcare professional.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('health insights card renders shared seed content',
        (tester) async {
      final storage = storageWith([
        AnalysisRecord(
          id: 'r1',
          date: DateTime(2025, 6, 15, 14, 30),
          condition: 'Asthma',
          percentage: 87,
        ),
      ]);

      await tester.pumpWidget(_buildHistory(storage: storage));
      await tester.pump();

      expect(find.textContaining('Understanding COPD'), findsOneWidget);
    });

    testWidgets('back button routes home', (tester) async {
      final storage = storageWith([
        AnalysisRecord(
          id: 'r1',
          date: DateTime(2025, 6, 15, 14, 30),
          condition: 'Asthma',
          percentage: 87,
        ),
      ]);

      await tester.pumpWidget(_buildHistoryRouter(storage: storage));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Home Destination'), findsOneWidget);
    });
  });

  group('HistoryScreen – period filters', () {
    late DateTime now;
    late FakeLocalStorageService storage;

    setUp(() {
      now = DateTime(2025, 6, 20, 12, 0);
      storage = FakeLocalStorageService()
        ..history = [
          // 3 days ago – within 7 days and 30 days
          AnalysisRecord(
            id: 'recent',
            date: DateTime(2025, 6, 17, 10, 0),
            condition: 'Asthma',
            percentage: 80,
          ).toJson(),
          // 10 days ago – within 30 days but NOT 7 days
          AnalysisRecord(
            id: 'mid',
            date: DateTime(2025, 6, 10, 10, 0),
            condition: 'Bronchitis',
            percentage: 70,
          ).toJson(),
          // 40 days ago – outside 30 days
          AnalysisRecord(
            id: 'old',
            date: DateTime(2025, 5, 11, 10, 0),
            condition: 'COPD',
            percentage: 60,
          ).toJson(),
        ];
    });

    testWidgets('All Time shows all records', (tester) async {
      await tester.pumpWidget(_buildHistory(storage: storage, now: now));
      await tester.pump();

      expect(find.text('Asthma'), findsOneWidget);
      expect(find.text('Bronchitis'), findsOneWidget);
      expect(find.text('COPD'), findsOneWidget);
    });

    testWidgets('Last 7 Days shows only records within 7 days', (tester) async {
      await tester.pumpWidget(_buildHistory(storage: storage, now: now));
      await tester.pump();

      await tester.tap(find.text('Last 7 Days'));
      await tester.pump();

      expect(find.text('Asthma'), findsOneWidget);
      expect(find.text('Bronchitis'), findsNothing);
      expect(find.text('COPD'), findsNothing);
    });

    testWidgets('Last 7 Days includes records exactly 7 days old',
        (tester) async {
      final boundaryStorage = FakeLocalStorageService()
        ..history = [
          AnalysisRecord(
            id: 'boundary-7',
            date: DateTime(2025, 6, 13, 12, 0),
            condition: 'Boundary Asthma',
            percentage: 81,
          ).toJson(),
        ];

      await tester.pumpWidget(_buildHistory(storage: boundaryStorage, now: now));
      await tester.pump();

      await tester.tap(find.text('Last 7 Days'));
      await tester.pump();

      expect(find.text('Boundary Asthma'), findsOneWidget);
    });

    testWidgets('Last 7 Days excludes future-dated records', (tester) async {
      final futureStorage = FakeLocalStorageService()
        ..history = [
          AnalysisRecord(
            id: 'recent',
            date: DateTime(2025, 6, 17, 10, 0),
            condition: 'Asthma',
            percentage: 80,
          ).toJson(),
          AnalysisRecord(
            id: 'future',
            date: DateTime(2025, 6, 22, 9, 0),
            condition: 'Future Condition',
            percentage: 90,
          ).toJson(),
        ];

      await tester.pumpWidget(_buildHistory(storage: futureStorage, now: now));
      await tester.pump();

      await tester.tap(find.text('Last 7 Days'));
      await tester.pump();

      expect(find.text('Asthma'), findsOneWidget);
      expect(find.text('Future Condition'), findsNothing);
    });

    testWidgets('Last 30 Days shows records within 30 days', (tester) async {
      await tester.pumpWidget(_buildHistory(storage: storage, now: now));
      await tester.pump();

      await tester.tap(find.text('Last 30 Days'));
      await tester.pump();

      expect(find.text('Asthma'), findsOneWidget);
      expect(find.text('Bronchitis'), findsOneWidget);
      expect(find.text('COPD'), findsNothing);
    });

    testWidgets('Last 30 Days includes records exactly 30 days old',
        (tester) async {
      final boundaryStorage = FakeLocalStorageService()
        ..history = [
          AnalysisRecord(
            id: 'boundary-30',
            date: DateTime(2025, 5, 21, 12, 0),
            condition: 'Boundary COPD',
            percentage: 61,
          ).toJson(),
        ];

      await tester.pumpWidget(_buildHistory(storage: boundaryStorage, now: now));
      await tester.pump();

      await tester.tap(find.text('Last 30 Days'));
      await tester.pump();

      expect(find.text('Boundary COPD'), findsOneWidget);
    });

    testWidgets(
        'switching from filtered view back to All Time restores all records',
        (tester) async {
      await tester.pumpWidget(_buildHistory(storage: storage, now: now));
      await tester.pump();

      await tester.tap(find.text('Last 7 Days'));
      await tester.pump();

      expect(find.text('COPD'), findsNothing);

      await tester.tap(find.text('All Time'));
      await tester.pump();

      expect(find.text('COPD'), findsOneWidget);
    });

    testWidgets(
        'filtered empty state shows No History Yet when no records match',
        (tester) async {
      final emptyStorage = FakeLocalStorageService()
        ..history = [
          // Only an old record
          AnalysisRecord(
            id: 'old',
            date: DateTime(2025, 5, 11, 10, 0),
            condition: 'COPD',
            percentage: 60,
          ).toJson(),
        ];

      await tester.pumpWidget(_buildHistory(storage: emptyStorage, now: now));
      await tester.pump();

      await tester.tap(find.text('Last 7 Days'));
      await tester.pump();

      expect(find.text('No History Yet'), findsOneWidget);
    });
  });

  testWidgets('tapping record card navigates to result with recordId',
      (tester) async {
    final record = AnalysisRecord(
      id: 'tap-test-123',
      date: DateTime(2026, 5, 20, 14, 30),
      condition: 'Bronchitis',
      percentage: 65,
    );

    final storage = FakeLocalStorageService()
      ..history = [record.toJson()];

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => ProviderScope(
            overrides: [localStorageServiceProvider.overrideWithValue(storage)],
            child: const HistoryScreen(),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/result',
          builder: (context, state) {
            final recordId = state.uri.queryParameters['recordId'];
            return Scaffold(
              body: Text('Result: $recordId'),
            );
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

    // Find and tap the record card
    final cardFinder = find.text('Bronchitis');
    expect(cardFinder, findsOneWidget);

    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Should navigate to result screen with recordId
    expect(find.text('Result: tap-test-123'), findsOneWidget);
  });

  testWidgets('allows normal back navigation with canPop: true',
      (tester) async {
    await tester.pumpWidget(
      _buildHistory(storage: FakeLocalStorageService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Symptom History'), findsOneWidget);

    // Verify PopScope is configured with canPop: true
    final popScope = tester.widget<PopScope>(find.byType(PopScope));
    expect(popScope.canPop, isTrue);
  });
}
