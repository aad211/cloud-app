import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/core/storage/local_storage_service.dart';
import 'package:ohok_flutter/features/onboarding/presentation/onboarding_screen.dart';

import '../../test_helpers/fake_local_storage_service.dart';

/// Minimal router harness that starts directly on [OnboardingScreen].
Widget _buildHarness(FakeLocalStorageService storage) {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Quick Actions'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('get started stores onboarding completion and routes home',
      (tester) async {
    final storage = FakeLocalStorageService();

    await tester.pumpWidget(_buildHarness(storage));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(storage.hasCompletedOnboarding, isTrue);
    expect(find.text('Quick Actions'), findsOneWidget);
  });

  testWidgets(
      'displays correct slide content per page and transitions Next to Get Started',
      (tester) async {
    final storage = FakeLocalStorageService();

    await tester.pumpWidget(_buildHarness(storage));
    await tester.pumpAndSettle();

    // Slide 1
    expect(find.text('Welcome to CLOUD'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);

    // Slide 2
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Simple Audio Recording'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Slide 3
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Daily Health Tracking'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Slide 4 – last: button must switch to 'Get Started'; Skip must be hidden
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Smart Recommendations'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('tapping Skip persists onboarding completion and navigates home',
      (tester) async {
    final storage = FakeLocalStorageService();

    await tester.pumpWidget(_buildHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(storage.hasCompletedOnboarding, isTrue);
    expect(find.text('Quick Actions'), findsOneWidget);
  });

  testWidgets(
      'stays on onboarding and shows SnackBar when persistence fails',
      (tester) async {
    final storage = FakeLocalStorageService()..shouldFailPersistence = true;

    await tester.pumpWidget(_buildHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Must NOT have navigated home
    expect(find.text('Quick Actions'), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    // SnackBar surfaces the failure
    expect(
      find.text('Failed to save progress. Please try again.'),
      findsOneWidget,
    );

    // Onboarding flag must NOT be set
    expect(storage.hasCompletedOnboarding, isFalse);
  });

  testWidgets('ignores repeated Skip taps while persistence is in progress',
      (tester) async {
    final storage = FakeLocalStorageService()
      ..persistenceDelay = const Duration(milliseconds: 300);

    await tester.pumpWidget(_buildHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.tap(find.text('Skip'));
    await tester.pump();

    expect(storage.setHasCompletedOnboardingCallCount, 1);

    await tester.pump(storage.persistenceDelay);
    await tester.pumpAndSettle();

    expect(find.text('Quick Actions'), findsOneWidget);
  });

  testWidgets('disables Next while a page transition is in progress',
      (tester) async {
    final storage = FakeLocalStorageService();

    await tester.pumpWidget(_buildHarness(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Simple Audio Recording'), findsOneWidget);
  });
}
