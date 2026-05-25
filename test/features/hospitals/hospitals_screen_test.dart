import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/features/hospitals/presentation/hospitals_screen.dart';

Widget _buildSubject() => const MaterialApp(home: HospitalsScreen());

Widget _buildHarness() {
  final router = GoRouter(
    initialLocation: '/hospitals',
    routes: [
      GoRoute(path: '/hospitals', builder: (_, __) => const HospitalsScreen()),
      GoRoute(
        path: '/home',
        builder:
            (_, __) =>
                const Scaffold(body: Center(child: Text('Home Destination'))),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('HospitalsScreen – static layout', () {
    testWidgets(
      'shows parity subtitle, map label, recommendation, count and actions',
      (tester) async {
        await tester.pumpWidget(_buildSubject());

        expect(find.text('Nearby Hospitals'), findsOneWidget);
        expect(find.text('Find medical help near you'), findsOneWidget);
        expect(find.text('📍 Your Location'), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Emergency Call'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Based on your symptoms, we recommend visiting a hospital for professional evaluation.',
          ),
          findsOneWidget,
        );
        expect(find.text('Nearby Hospitals (4)'), findsOneWidget);
        expect(find.text('Call'), findsNWidgets(4));
        expect(find.text('Directions'), findsNWidgets(4));
      },
    );

    testWidgets('shows search field with correct hint', (tester) async {
      await tester.pumpWidget(_buildSubject());
      expect(
        find.widgetWithText(TextField, 'Search hospital...'),
        findsOneWidget,
      );
    });

    testWidgets('shows the planned hospital seed entries by default', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject());
      expect(find.text('City General Hospital'), findsOneWidget);
      expect(find.text('St. Mary Medical Center'), findsOneWidget);
      expect(find.text('Metropolitan Health Clinic'), findsOneWidget);
      expect(find.text('1.2 km'), findsOneWidget);
      expect(find.text('123 Main St, Downtown'), findsOneWidget);
      expect(find.text('2.1 km'), findsOneWidget);
      expect(find.text('456 Oak Ave, Central'), findsOneWidget);
      expect(find.text('3.5 km'), findsOneWidget);
      expect(find.text('789 Pine Rd, Uptown'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Riverside Hospital'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Riverside Hospital'), findsOneWidget);
      expect(find.text('4.8 km'), findsOneWidget);
      expect(find.text('321 River St, Westside'), findsOneWidget);
    });

    testWidgets('wraps the screen body in SafeArea', (tester) async {
      await tester.pumpWidget(_buildSubject());

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.body, isA<SafeArea>());
    });

    testWidgets('routes home from parity back button', (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Home Destination'), findsOneWidget);
    });
  });

  group('HospitalsScreen – local search', () {
    testWidgets('filters list when query matches one hospital', (tester) async {
      await tester.pumpWidget(_buildSubject());

      await tester.enterText(
        find.widgetWithText(TextField, 'Search hospital...'),
        'riverside',
      );
      await tester.pump();

      expect(find.text('Riverside Hospital'), findsOneWidget);
      expect(find.text('City General Hospital'), findsNothing);
    });

    testWidgets('shows all hospitals when query is cleared', (tester) async {
      await tester.pumpWidget(_buildSubject());

      await tester.enterText(
        find.widgetWithText(TextField, 'Search hospital...'),
        'riverside',
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'Search hospital...'),
        '',
      );
      await tester.pump();

      expect(find.text('City General Hospital'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Riverside Hospital'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Riverside Hospital'), findsOneWidget);
    });

    testWidgets('shows empty list when query matches nothing', (tester) async {
      await tester.pumpWidget(_buildSubject());

      await tester.enterText(
        find.widgetWithText(TextField, 'Search hospital...'),
        'zzznomatch',
      );
      await tester.pump();

      expect(find.text('City General Hospital'), findsNothing);
      expect(find.text('Riverside Hospital'), findsNothing);
    });

    testWidgets('search is case-insensitive', (tester) async {
      await tester.pumpWidget(_buildSubject());

      await tester.enterText(
        find.widgetWithText(TextField, 'Search hospital...'),
        'CITY',
      );
      await tester.pump();

      expect(find.text('City General Hospital'), findsOneWidget);
      expect(find.text('Riverside Hospital'), findsNothing);
    });
  });
}
