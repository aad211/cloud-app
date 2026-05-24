import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohok_flutter/features/articles/presentation/articles_screen.dart';

void main() {
  testWidgets('switches from articles to news tab', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ArticlesScreen()));

    expect(find.text('Asthma'), findsOneWidget);
    expect(
      find.text('New AI Algorithm Detects Lung Diseases Earlier'),
      findsNothing,
    );

    await tester.tap(find.text('News'));
    await tester.pumpAndSettle();

    expect(find.text('Asthma'), findsNothing);
    expect(
      find.text('New AI Algorithm Detects Lung Diseases Earlier'),
      findsOneWidget,
    );
  });
}
