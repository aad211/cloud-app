import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohok_flutter/app/app.dart';
import 'package:ohok_flutter/core/storage/local_storage_service.dart';
import '../../test_helpers/fake_local_storage_service.dart';

void main() {
  testWidgets('get started stores onboarding completion and routes home', (tester) async {
    final storage = FakeLocalStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
        child: const OhokApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
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

  testWidgets('displays correct slide content per page and transitions Next to Get Started', (tester) async {
    final storage = FakeLocalStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
        child: const OhokApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
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

  testWidgets('tapping Skip persists onboarding completion and navigates home', (tester) async {
    final storage = FakeLocalStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
        child: const OhokApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(storage.hasCompletedOnboarding, isTrue);
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
