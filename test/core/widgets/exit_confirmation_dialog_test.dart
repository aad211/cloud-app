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
  });
}
