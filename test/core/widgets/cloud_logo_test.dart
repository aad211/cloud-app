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

    testWidgets('applies small size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CloudLogo(size: CloudLogoSize.small),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 24.0);

      final text = tester.widget<Text>(find.text('CLOUD'));
      expect(text.style?.fontSize, 16.0);
    });

    testWidgets('applies medium size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CloudLogo(size: CloudLogoSize.medium),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 40.0);

      final text = tester.widget<Text>(find.text('CLOUD'));
      expect(text.style?.fontSize, 28.0);
    });

    testWidgets('applies large size correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CloudLogo(size: CloudLogoSize.large),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 120.0);

      final text = tester.widget<Text>(find.text('CLOUD'));
      expect(text.style?.fontSize, 56.0);
      expect(text.style?.letterSpacing, 2.0);
    });

    testWidgets('uses default navy colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CloudLogo(),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, AppColors.navy);

      final text = tester.widget<Text>(find.text('CLOUD'));
      expect(text.style?.color, AppColors.navy);
    });

    testWidgets('applies custom iconColor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CloudLogo(iconColor: Colors.white),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, Colors.white);
    });

    testWidgets('applies custom textColor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CloudLogo(textColor: Colors.red),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('CLOUD'));
      expect(text.style?.color, Colors.red);
    });

    testWidgets('applies both custom colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CloudLogo(
              iconColor: Colors.blue,
              textColor: Colors.green,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, Colors.blue);

      final text = tester.widget<Text>(find.text('CLOUD'));
      expect(text.style?.color, Colors.green);
    });
  });
}
