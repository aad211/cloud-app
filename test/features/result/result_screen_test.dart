import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/core/models/analysis_record.dart';
import 'package:ohok_flutter/core/models/condition_probability.dart';
import 'package:ohok_flutter/core/storage/local_storage_service.dart';
import 'package:ohok_flutter/features/analysis/presentation/latest_analysis_provider.dart';
import 'package:ohok_flutter/features/result/presentation/result_screen.dart';

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
