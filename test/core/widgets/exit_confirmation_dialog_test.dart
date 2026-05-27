import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_app/core/widgets/exit_confirmation_dialog.dart';

void main() {
  group('showExitConfirmationDialog', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showExitConfirmationDialog(context),
              child: const Text('Test'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      expect(find.text('Exit App?'), findsOneWidget);
      expect(find.text('Are you sure you want to exit CLOUD?'), findsOneWidget);
    });

    testWidgets('returns false when Cancel button is tapped', (tester) async {
      bool? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showExitConfirmationDialog(context);
              },
              child: const Text('Test'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, false);
      expect(find.text('Exit App?'), findsNothing);
    });

    testWidgets('returns true when Exit button is tapped', (tester) async {
      bool? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showExitConfirmationDialog(context);
              },
              child: const Text('Test'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Exit'));
      await tester.pumpAndSettle();

      expect(result, true);
      expect(find.text('Exit App?'), findsNothing);
    });

    testWidgets('returns false when dismissed by tapping outside', (tester) async {
      bool? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showExitConfirmationDialog(context);
              },
              child: const Text('Test'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();
      
      // Tap outside dialog (barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(result, false);
      expect(find.text('Exit App?'), findsNothing);
    });
  });
}
