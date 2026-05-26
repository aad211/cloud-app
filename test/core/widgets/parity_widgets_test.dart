import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_flutter/app/theme/app_colors.dart';
import 'package:cloud_flutter/core/widgets/condition_visuals.dart';
import 'package:cloud_flutter/core/widgets/parity_cards.dart';
import 'package:cloud_flutter/core/widgets/parity_page_header.dart';

void main() {
  group('conditionVisualsFor', () {
    test('returns success visuals for Healthy', () {
      final visuals = conditionVisualsFor('Healthy');

      expect(visuals.emoji, '✅');
      expect(visuals.color, AppColors.success);
    });

    test('returns lung visuals for Asthma', () {
      final visuals = conditionVisualsFor('Asthma');

      expect(visuals.emoji, '🫁');
      expect(visuals.color, AppColors.blue);
    });

    test('returns gold visuals for Bronchitis', () {
      final visuals = conditionVisualsFor('Bronchitis');

      expect(visuals.emoji, '🤒');
      expect(visuals.color, AppColors.gold);
    });

    test('returns danger visuals for Pneumonia', () {
      final visuals = conditionVisualsFor('Pneumonia');

      expect(visuals.emoji, '🦠');
      expect(visuals.color, AppColors.danger);
    });

    test('returns danger visuals for COVID-19', () {
      final visuals = conditionVisualsFor('COVID-19');

      expect(visuals.emoji, '🦠');
      expect(visuals.color, AppColors.danger);
    });

    test('returns critical visuals for Lung Cancer', () {
      final visuals = conditionVisualsFor('Lung Cancer');

      expect(visuals.emoji, '⚠️');
      expect(visuals.color, const Color(0xFF991B1B));
    });

    test('falls back to lung visuals for unknown conditions', () {
      final visuals = conditionVisualsFor('Unknown condition');

      expect(visuals.emoji, '🫁');
      expect(visuals.color, AppColors.blue);
    });
  });

  group('ParityPageHeader', () {
    testWidgets('renders title and subtitle and handles back tap', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParityPageHeader(
              title: 'Analysis Result',
              subtitle: 'Based on your cough recording',
              onBack: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Analysis Result'), findsOneWidget);
      expect(find.text('Based on your cough recording'), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      expect(tapped, isTrue);
    });
  });

  group('Parity cards', () {
    testWidgets('ParityGradientCard renders its child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: ParityGradientCard(child: Text('Card content')),
            ),
          ),
        ),
      );

      expect(find.text('Card content'), findsOneWidget);
    });

    testWidgets('ParityInfoCard shows leading and child content', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ParityInfoCard(
              leading: Icon(Icons.info),
              child: Text('Helpful information'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);
      expect(find.text('Helpful information'), findsOneWidget);
    });

    testWidgets('ParityDisclaimerCard renders the React warning copy', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ParityDisclaimerCard(
              message:
                  '⚠️ This is not a medical diagnosis. Please consult a healthcare professional.',
            ),
          ),
        ),
      );

      expect(
        find.text(
          '⚠️ This is not a medical diagnosis. Please consult a healthcare professional.',
        ),
        findsOneWidget,
      );
    });
  });
}
