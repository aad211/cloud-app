import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/features/articles/presentation/articles_screen.dart';

Widget _buildHarness() {
  final router = GoRouter(
    initialLocation: '/articles',
    routes: [
      GoRoute(path: '/articles', builder: (_, __) => const ArticlesScreen()),
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
  testWidgets('renders parity header and routes home from back button', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    expect(find.text('Articles and News'), findsOneWidget);
    expect(
      find.text('Learn about respiratory conditions and lung health'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Home Destination'), findsOneWidget);
  });

  testWidgets('articles tab shows parity article content', (tester) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Our AI analyzes cough audio patterns to detect potential respiratory conditions. This is not a medical diagnosis - always consult healthcare professionals.',
      ),
      findsOneWidget,
    );

    for (final disease in const [
      'Asthma',
      'Bronchitis',
      'Pneumonia',
      'COVID-19',
      'Lung Cancer',
      'Healthy',
    ]) {
      await tester.scrollUntilVisible(
        find.text(disease),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(disease), findsOneWidget);
    }

    await tester.scrollUntilVisible(
      find.text('Educational Articles'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Educational Articles'), findsOneWidget);
  });

  testWidgets('news tab shows parity news content', (tester) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('News'));
    await tester.pumpAndSettle();

    expect(find.text('Latest Health News'), findsOneWidget);
    expect(
      find.text('COVID-19 Variant Update: What You Need to Know'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('World No Tobacco Day Campaign Launched'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('World No Tobacco Day Campaign Launched'), findsOneWidget);
  });
}
