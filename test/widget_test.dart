import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohok_flutter/app/app.dart';

void main() {
  testWidgets('boots the OHOK app shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OhokApp()));
    expect(find.text('OHOK'), findsOneWidget);
  });
}
