import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohok_flutter/app/app.dart';

void main() {
  testWidgets('boots into splash screen showing CLOUD', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OhokApp()));
    await tester.pump();
    expect(find.text('CLOUD'), findsOneWidget);
  });
}
