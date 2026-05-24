import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohok_flutter/app/app.dart';
import 'package:ohok_flutter/core/storage/local_storage_service.dart';

import '../test_helpers/fake_local_storage_service.dart';

void main() {
  testWidgets('shows splash inside the centered mobile frame', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(
            FakeLocalStorageService(),
          ),
        ],
        child: const OhokApp(),
      ),
    );

    await tester.pump();

    expect(find.text('CLOUD'), findsOneWidget);
    expect(find.byKey(const Key('mobile-frame')), findsOneWidget);
  });

  testWidgets(
    'navigates to onboarding destination after splash timer when onboarding is incomplete',
    (tester) async {
      final fakeStorage = FakeLocalStorageService()
        ..hasCompletedOnboarding = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(fakeStorage),
          ],
          child: const OhokApp(),
        ),
      );
      await tester.pump();

      // Advance past the 2-second splash timer.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to CLOUD'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    },
  );

  testWidgets(
    'navigates to home destination after splash timer when onboarding is complete',
    (tester) async {
      final fakeStorage = FakeLocalStorageService()
        ..hasCompletedOnboarding = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(fakeStorage),
          ],
          child: const OhokApp(),
        ),
      );
      await tester.pump();

      // Advance past the 2-second splash timer.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('CLOUD'), findsNothing);
    },
  );

  testWidgets('OhokApp disposes without errors when removed from tree',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(
            FakeLocalStorageService(),
          ),
        ],
        child: const OhokApp(),
      ),
    );
    await tester.pump();

    // Replace the widget tree — should trigger dispose on _OhokAppState.
    await tester.pumpWidget(const SizedBox());

    // No exceptions means dispose ran cleanly.
    expect(tester.takeException(), isNull);
  });
}
