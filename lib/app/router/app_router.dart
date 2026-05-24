import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/features/home/presentation/home_screen.dart';
import 'package:ohok_flutter/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ohok_flutter/features/onboarding/presentation/splash_screen.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );
}
