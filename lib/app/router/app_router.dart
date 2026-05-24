import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/features/onboarding/presentation/splash_screen.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    ],
  );
}
