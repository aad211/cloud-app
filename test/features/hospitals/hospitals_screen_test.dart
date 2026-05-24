import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohok_flutter/features/hospitals/presentation/hospitals_screen.dart';

Widget _buildSubject() => const MaterialApp(home: HospitalsScreen());

void main() {
  group('HospitalsScreen – static layout', () {
    testWidgets('shows Nearby Hospitals heading', (tester) async {
      await tester.pumpWidget(_buildSubject());
      expect(find.text('Nearby Hospitals'), findsOneWidget);
    });

    testWidgets('shows search field with correct hint', (tester) async {
      await tester.pumpWidget(_buildSubject());
      expect(find.widgetWithText(TextField, 'Search hospital...'),
          findsOneWidget);
    });

    testWidgets('shows all seed hospitals by default', (tester) async {
      await tester.pumpWidget(_buildSubject());
      expect(find.text('City General Hospital'), findsOneWidget);
      expect(find.text('Riverside Hospital'), findsOneWidget);
    });

    testWidgets('shows Emergency Call button (disabled)', (tester) async {
      await tester.pumpWidget(_buildSubject());
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Emergency Call'),
      );
      expect(btn.onPressed, isNull);
    });
  });

  group('HospitalsScreen – local search', () {
    testWidgets('filters list when query matches one hospital', (tester) async {
      await tester.pumpWidget(_buildSubject());

      await tester.enterText(
          find.widgetWithText(TextField, 'Search hospital...'), 'riverside');
      await tester.pump();

      expect(find.text('Riverside Hospital'), findsOneWidget);
      expect(find.text('City General Hospital'), findsNothing);
    });

    testWidgets('shows all hospitals when query is cleared', (tester) async {
      await tester.pumpWidget(_buildSubject());

      await tester.enterText(
          find.widgetWithText(TextField, 'Search hospital...'), 'riverside');
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextField, 'Search hospital...'), '');
      await tester.pump();

      expect(find.text('City General Hospital'), findsOneWidget);
      expect(find.text('Riverside Hospital'), findsOneWidget);
    });

    testWidgets('shows empty list when query matches nothing', (tester) async {
      await tester.pumpWidget(_buildSubject());

      await tester.enterText(
          find.widgetWithText(TextField, 'Search hospital...'), 'zzznomatch');
      await tester.pump();

      expect(find.text('City General Hospital'), findsNothing);
      expect(find.text('Riverside Hospital'), findsNothing);
    });

    testWidgets('search is case-insensitive', (tester) async {
      await tester.pumpWidget(_buildSubject());

      await tester.enterText(
          find.widgetWithText(TextField, 'Search hospital...'), 'CITY');
      await tester.pump();

      expect(find.text('City General Hospital'), findsOneWidget);
      expect(find.text('Riverside Hospital'), findsNothing);
    });
  });
}
