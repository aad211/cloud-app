import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/app/router/app_router.dart';
import 'package:ohok_flutter/core/models/analysis_record.dart';
import 'package:ohok_flutter/core/storage/local_storage_service.dart';
import 'package:ohok_flutter/features/home/presentation/home_screen.dart';

import '../../test_helpers/fake_local_storage_service.dart';

Widget _buildHome({required FakeLocalStorageService storage}) {
  return ProviderScope(
    overrides: [
      localStorageServiceProvider.overrideWithValue(storage),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  group('HomeScreen – empty history', () {
    testWidgets('shows empty-state card with no-analysis copy', (tester) async {
      final storage = FakeLocalStorageService();

      await tester.pumpWidget(_buildHome(storage: storage));
      await tester.pump(); // allow async build() to complete

      expect(find.text('No Analysis Yet'), findsOneWidget);
      expect(find.text('Latest Analysis'), findsNothing);
    });

    testWidgets('shows Quick Actions heading and Check Symptoms button',
        (tester) async {
      final storage = FakeLocalStorageService();

      await tester.pumpWidget(_buildHome(storage: storage));
      await tester.pump();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Check Symptoms'), findsOneWidget);
    });

    testWidgets('shows secondary quick-action buttons', (tester) async {
      final storage = FakeLocalStorageService();

      await tester.pumpWidget(_buildHome(storage: storage));
      await tester.pump();

      expect(find.text('History'), findsOneWidget);
      expect(find.text('Hospitals'), findsOneWidget);
      expect(find.text('Articles'), findsOneWidget);
    });
  });

  group('HomeScreen – with saved history', () {
    FakeLocalStorageService storageWithRecord() {
      final storage = FakeLocalStorageService();
      final record = AnalysisRecord(
        id: 'test-1',
        date: DateTime(2025, 6, 15, 14, 30),
        condition: 'Asthma',
        percentage: 87,
      );
      storage.history = [record.toJson()];
      return storage;
    }

    testWidgets('shows Latest Analysis heading', (tester) async {
      await tester.pumpWidget(_buildHome(storage: storageWithRecord()));
      await tester.pump();

      expect(find.text('Latest Analysis'), findsOneWidget);
    });

    testWidgets('shows condition name', (tester) async {
      await tester.pumpWidget(_buildHome(storage: storageWithRecord()));
      await tester.pump();

      expect(find.text('Asthma'), findsOneWidget);
    });

    testWidgets('shows percentage', (tester) async {
      await tester.pumpWidget(_buildHome(storage: storageWithRecord()));
      await tester.pump();

      expect(find.text('87%'), findsOneWidget);
    });

    testWidgets('shows formatted timestamp', (tester) async {
      await tester.pumpWidget(_buildHome(storage: storageWithRecord()));
      await tester.pump();

      // DateFormat('MMMM d, y • hh:mm a') for 2025-06-15 14:30
      expect(find.text('June 15, 2025 • 02:30 PM'), findsOneWidget);
    });
  });

  group('AppRouter – placeholder routes present', () {
    test('router has /check-symptoms route', () {
      final router = buildRouter();
      final routes = router.configuration.routes;
      final paths = _collectPaths(routes);
      expect(paths, contains('/check-symptoms'));
    });

    test('router has /history route', () {
      final router = buildRouter();
      final paths = _collectPaths(router.configuration.routes);
      expect(paths, contains('/history'));
    });

    test('router has /hospitals route', () {
      final router = buildRouter();
      final paths = _collectPaths(router.configuration.routes);
      expect(paths, contains('/hospitals'));
    });

    test('router has /articles route', () {
      final router = buildRouter();
      final paths = _collectPaths(router.configuration.routes);
      expect(paths, contains('/articles'));
    });
  });
}

List<String> _collectPaths(List<RouteBase> routes) {
  final result = <String>[];
  for (final r in routes) {
    if (r is GoRoute) result.add(r.path);
    result.addAll(_collectPaths(r.routes));
  }
  return result;
}
