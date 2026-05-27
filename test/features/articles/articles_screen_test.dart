import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_app/features/articles/presentation/articles_screen.dart';

Widget _buildHarness({
  Future<bool> Function(BuildContext context, String url)? openLink,
}) {
  final router = GoRouter(
    initialLocation: '/articles',
    routes: [
      GoRoute(
        path: '/articles',
        builder: (_, __) => ArticlesScreen(openLink: openLink ?? _noopOpenLink),
      ),
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

Future<bool> _noopOpenLink(BuildContext _, String __) async => true;

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

  testWidgets('article Read more opens article URL', (tester) async {
    String? openedUrl;

    await tester.pumpWidget(
      _buildHarness(
        openLink: (context, url) async {
          openedUrl = url;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Educational Articles'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Read more').first);
    await tester.pumpAndSettle();

    expect(openedUrl, isNotNull);
    expect(openedUrl, startsWith('https://'));
  });

  testWidgets('news Read more opens news URL', (tester) async {
    String? openedUrl;

    await tester.pumpWidget(
      _buildHarness(
        openLink: (context, url) async {
          openedUrl = url;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('News'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read more').first);
    await tester.pumpAndSettle();

    expect(openedUrl, isNotNull);
    expect(openedUrl, startsWith('https://'));
  });

  testWidgets('has PopScope with canPop: true for normal navigation',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ArticlesScreen()));
    await tester.pumpAndSettle();

    final popScope = tester.widget<PopScope>(find.byType(PopScope));
    expect(popScope.canPop, isTrue);
  });
}
