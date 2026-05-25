import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/features/result/presentation/result_screen.dart';

Widget _buildHarness() {
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

  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('renders the parity result content', (tester) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    expect(find.text('Analysis Result'), findsOneWidget);
    expect(find.text('Based on your cough recording'), findsOneWidget);
    expect(find.text('Medium Risk'), findsOneWidget);
    expect(find.text('Probability Breakdown'), findsOneWidget);
    expect(find.text('What you should do'), findsOneWidget);
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
    'routes home from the header back button and hospitals from CTA',
    (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Home Destination'), findsOneWidget);

      await tester.pumpWidget(_buildHarness());
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
    },
  );
}
