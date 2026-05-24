import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/features/onboarding/presentation/splash_screen.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Onboarding')),
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home')),
        ),
      ),
    ],
  );
}
