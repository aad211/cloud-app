import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohok_flutter/app/app.dart';
import 'package:ohok_flutter/core/storage/local_storage_service.dart';
import '../../test_helpers/fake_local_storage_service.dart';

void main() {
  testWidgets('analyze requires recording and saves a mocked result',
      (tester) async {
    final storage = FakeLocalStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
        child: const OhokApp(),
      ),
    );

    storage.hasCompletedOnboarding = true;
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check Symptoms'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analyze Now'));
    await tester.pumpAndSettle();
    expect(find.text('Please record your cough first'), findsOneWidget);

    await tester.tap(find.text('Tap to record your cough'));
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analyze Now'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Analysis Result'), findsOneWidget);
    expect(storage.history, isNotEmpty);
  });
}
