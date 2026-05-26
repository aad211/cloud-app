import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_flutter/app/app.dart';
import 'package:cloud_flutter/core/storage/local_storage_service.dart';
import 'package:cloud_flutter/features/onboarding/presentation/onboarding_screen.dart';

import '../test_helpers/fake_local_storage_service.dart';

/// Storage double that throws on [getHasCompletedOnboarding] to simulate a
/// storage failure (e.g. corrupted SharedPreferences, platform exception).
class _ThrowingStorageService extends FakeLocalStorageService {
  @override
  Future<bool> getHasCompletedOnboarding() =>
      Future.error(StateError('storage unavailable'));
}

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
      expect(find.byType(OnboardingScreen), findsOneWidget);
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
      // Home screen now shows 'CLOUD' branding — verify we landed on HomeScreen.
      expect(find.text('CLOUD'), findsOneWidget);
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

  testWidgets(
    'deep-link to a protected route redirects to onboarding when incomplete',
    (tester) async {
      final fakeStorage = FakeLocalStorageService()
        ..hasCompletedOnboarding = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(fakeStorage),
          ],
          child: const OhokApp(initialLocation: '/home'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
    },
  );

  testWidgets(
    'direct /onboarding route redirects to home when onboarding is already complete',
    (tester) async {
      final fakeStorage = FakeLocalStorageService()
        ..hasCompletedOnboarding = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(fakeStorage),
          ],
          child: const OhokApp(initialLocation: '/onboarding'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
    },
  );

  testWidgets(
    'deep-link to protected route redirects to onboarding when storage read throws',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider
                .overrideWithValue(_ThrowingStorageService()),
          ],
          child: const OhokApp(initialLocation: '/home'),
        ),
      );
      // Let the initial frame render, then give the async Future.error time
      // to propagate through the microtask queue.
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump(); // router re-evaluates after guard notifyListeners

      // After the storage error the guard must finish loading (with safe
      // default: not onboarded) and redirect away from the protected route.
      expect(find.byType(OnboardingScreen), findsOneWidget,
          reason: 'Storage error should redirect to onboarding as safe default');
    },
  );
}
