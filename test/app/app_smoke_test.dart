import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_flutter/app/app.dart';
import 'package:cloud_flutter/core/storage/local_storage_service.dart';
import '../test_helpers/fake_local_storage_service.dart';

void main() {
  testWidgets('supports the main end-to-end prototype flow', (tester) async {
    final storage = FakeLocalStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
        child: const OhokApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to CLOUD'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Quick Actions'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Symptom History'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
