import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:cloud_flutter/core/models/analysis_record.dart';
import 'package:cloud_flutter/core/storage/local_storage_service.dart';
import 'package:cloud_flutter/features/home/presentation/home_screen.dart';

import '../../test_helpers/fake_local_storage_service.dart';

Widget _buildHome({required FakeLocalStorageService storage}) {
  return ProviderScope(
    overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    child: const MaterialApp(home: HomeScreen()),
  );
}

Widget _buildHomeRouter({required FakeLocalStorageService storage}) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/check-symptoms',
        builder:
            (_, __) => const Scaffold(
              body: Center(child: Text('Check Symptoms Page')),
            ),
      ),
      GoRoute(
        path: '/history',
        builder:
            (_, __) =>
                const Scaffold(body: Center(child: Text('History Page'))),
      ),
      GoRoute(
        path: '/hospitals',
        builder:
            (_, __) =>
                const Scaffold(body: Center(child: Text('Hospitals Page'))),
      ),
      GoRoute(
        path: '/articles',
        builder:
            (_, __) =>
                const Scaffold(body: Center(child: Text('Articles Page'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    child: MaterialApp.router(routerConfig: router),
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

    testWidgets('shows an error state when history fails to load', (
      tester,
    ) async {
      final storage = FakeLocalStorageService()
        ..historyLoadException = Exception('load failed');

      await tester.pumpWidget(_buildHome(storage: storage));
      await tester.pump();
      await tester.pump();

      expect(find.text('Unable to load analysis history'), findsOneWidget);
      expect(find.text('No Analysis Yet'), findsNothing);
    });

    testWidgets('shows Quick Actions heading and Check Symptoms button', (
      tester,
    ) async {
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
      expect(find.text('Hospital'), findsOneWidget);
      expect(find.text('Articles'), findsOneWidget);
    });

    testWidgets('shows health insights cards and disclaimer copy', (
      tester,
    ) async {
      final storage = FakeLocalStorageService();

      await tester.pumpWidget(_buildHome(storage: storage));
      await tester.pump();

      expect(find.text('Health Insights'), findsOneWidget);
      expect(find.text('Understanding COPD'), findsOneWidget);
      expect(find.text('Air Quality Tips'), findsOneWidget);
      expect(find.text('Quit Smoking Guide'), findsOneWidget);
      expect(find.text('Read more'), findsNWidgets(3));
      expect(
        find.text(
          '⚠️ Not a medical diagnosis. Consult healthcare professionals.',
        ),
        findsOneWidget,
      );
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

    testWidgets(
      'uses English timestamp formatting regardless of ambient locale',
      (tester) async {
        final originalLocale = Intl.defaultLocale;
        await initializeDateFormatting('id_ID');
        Intl.defaultLocale = 'id_ID';
        addTearDown(() => Intl.defaultLocale = originalLocale);

        await tester.pumpWidget(_buildHome(storage: storageWithRecord()));
        await tester.pump();

        expect(find.text('June 15, 2025 • 02:30 PM'), findsOneWidget);
      },
    );

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

    testWidgets('renders latest-analysis percentage in white', (tester) async {
      final storage = FakeLocalStorageService();
      final record = AnalysisRecord(
        id: 'test-white',
        date: DateTime(2025, 6, 15, 14, 30),
        condition: 'Healthy',
        percentage: 87,
      );
      storage.history = [record.toJson()];

      await tester.pumpWidget(_buildHome(storage: storage));
      await tester.pump();

      final text = tester.widget<Text>(find.text('87%'));
      expect(text.style?.color, Colors.white);
    });

    testWidgets('shows formatted timestamp', (tester) async {
      await tester.pumpWidget(_buildHome(storage: storageWithRecord()));
      await tester.pump();

      // DateFormat('MMMM d, y • hh:mm a') for 2025-06-15 14:30
      expect(find.text('June 15, 2025 • 02:30 PM'), findsOneWidget);
    });

    testWidgets('shows condition emoji and confidence label', (tester) async {
      await tester.pumpWidget(_buildHome(storage: storageWithRecord()));
      await tester.pump();

      expect(find.text('🫁'), findsWidgets);
      expect(find.text('Confidence'), findsOneWidget);
    });
  });

  group('HomeScreen quick actions', () {
    testWidgets('navigates to Check Symptoms from the primary CTA', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildHomeRouter(storage: FakeLocalStorageService()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Check Symptoms'));
      await tester.pumpAndSettle();

      expect(find.text('Check Symptoms Page'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('navigates to History from the secondary action', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildHomeRouter(storage: FakeLocalStorageService()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('History Page'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('navigates to Hospitals from the secondary action', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildHomeRouter(storage: FakeLocalStorageService()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hospital'));
      await tester.pumpAndSettle();

      expect(find.text('Hospitals Page'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('navigates to Articles from the secondary action', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildHomeRouter(storage: FakeLocalStorageService()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Articles'));
      await tester.pumpAndSettle();

      expect(find.text('Articles Page'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('uses React-parity singular Hospital label', (tester) async {
      await tester.pumpWidget(_buildHome(storage: FakeLocalStorageService()));
      await tester.pump();

      expect(find.text('Hospital'), findsOneWidget);
      expect(find.text('Hospitals'), findsNothing);
    });

    testWidgets(
      'Check Symptoms primary CTA preserves Home in back stack after push',
      (tester) async {
        await tester.pumpWidget(
          _buildHomeRouter(storage: FakeLocalStorageService()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Check Symptoms'));
        await tester.pumpAndSettle();

        expect(find.text('Check Symptoms Page'), findsOneWidget);
        // With push (not go), GoRouter can pop back to Home.
        final router = GoRouter.of(
          tester.element(find.text('Check Symptoms Page')),
        );
        expect(router.canPop(), isTrue);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets('Hospital secondary action preserves Home in back stack', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildHomeRouter(storage: FakeLocalStorageService()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hospital'));
      await tester.pumpAndSettle();

      expect(find.text('Hospitals Page'), findsOneWidget);
      // With push (not go), GoRouter can pop back to Home.
      final router = GoRouter.of(tester.element(find.text('Hospitals Page')));
      expect(router.canPop(), isTrue);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
