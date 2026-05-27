import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_app/core/widgets/cloud_logo.dart';
import 'package:cloud_app/app/theme/app_colors.dart';

void main() {
  group('CloudLogo', () {
    testWidgets('renders Icon and Text widgets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CloudLogo(),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
      expect(find.text('CLOUD'), findsOneWidget);
    });
  });
}
