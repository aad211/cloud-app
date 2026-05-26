import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_flutter/core/storage/local_storage_service.dart';
import 'package:cloud_flutter/features/analysis/presentation/check_symptoms_screen.dart';
import 'package:cloud_flutter/features/articles/presentation/articles_screen.dart';
import 'package:cloud_flutter/features/history/presentation/history_screen.dart';
import 'package:cloud_flutter/features/home/presentation/home_screen.dart';
import 'package:cloud_flutter/features/onboarding/presentation/onboarding_screen.dart';
import 'package:cloud_flutter/features/onboarding/presentation/splash_screen.dart';
import 'package:cloud_flutter/features/hospitals/presentation/hospitals_screen.dart';
import 'package:cloud_flutter/features/result/presentation/result_screen.dart';

/// Tracks onboarding completion for GoRouter's redirect guard.
///
/// The guard loads the persisted state once on construction and notifies
/// GoRouter via [ChangeNotifier] so the router can perform a synchronous
/// redirect instead of an async one (async redirects cause pumpAndSettle to
/// loop in tests and add unnecessary overhead in production).
class OnboardingGuard extends ChangeNotifier {
  OnboardingGuard(LocalStorageService storage) {
    storage.getHasCompletedOnboarding().then((done) {
      _isLoaded = true;
      _isOnboarded = done;
      notifyListeners();
    }).catchError((Object _) {
      // Safe default on storage failure: treat user as not onboarded so
      // protected routes are still guarded even if persistence is unavailable.
      _isLoaded = true;
      _isOnboarded = false;
      notifyListeners();
    });
  }

  bool _isLoaded = false;
  bool _isOnboarded = false;

  bool get isLoaded => _isLoaded;
  bool get isOnboarded => _isOnboarded;

  /// Called by [OnboardingScreen] after successfully persisting completion.
  /// Updates the in-memory flag and notifies GoRouter to re-run redirect.
  void markOnboarded() {
    _isLoaded = true;
    _isOnboarded = true;
    notifyListeners();
  }
}

/// Riverpod provider so the onboarding screen can call [OnboardingGuard.markOnboarded]
/// without requiring constructor injection.
final onboardingGuardProvider = ChangeNotifierProvider<OnboardingGuard>((ref) {
  return OnboardingGuard(ref.read(localStorageServiceProvider));
});

GoRouter buildRouter({
  required OnboardingGuard onboardingGuard,
  String? initialLocation,
}) {
  return GoRouter(
    initialLocation: initialLocation ?? '/',
    refreshListenable: onboardingGuard,
    redirect: (context, state) {
      // Guard not loaded yet — let the current route through; the router will
      // re-evaluate once the guard notifies after the async load finishes.
      if (!onboardingGuard.isLoaded) return null;

      final path = state.uri.path;
      final isOnboarded = onboardingGuard.isOnboarded;

      if (!isOnboarded) {
        // Allow splash and onboarding; guard everything else.
        if (path == '/' || path == '/onboarding') return null;
        return '/onboarding';
      }

      // Onboarding complete — redirect /onboarding to home.
      if (path == '/onboarding') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen()),
      GoRoute(
          path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
          path: '/check-symptoms',
          builder: (context, state) => const CheckSymptomsScreen()),
      GoRoute(
          path: '/result',
          builder: (context, state) => const ResultScreen()),
      GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen()),
      GoRoute(
          path: '/hospitals',
          builder: (context, state) => const HospitalsScreen()),
      GoRoute(
          path: '/articles',
          builder: (context, state) => const ArticlesScreen()),
    ],
  );
}
