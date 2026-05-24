import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/features/home/presentation/home_screen.dart';
import 'package:ohok_flutter/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ohok_flutter/features/onboarding/presentation/splash_screen.dart';

Widget _placeholder(String title) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen()),
      GoRoute(
          path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
          path: '/check-symptoms',
          builder: (context, state) => _placeholder('Check Symptoms')),
      GoRoute(
          path: '/history',
          builder: (context, state) => _placeholder('History')),
      GoRoute(
          path: '/hospitals',
          builder: (context, state) => _placeholder('Hospitals')),
      GoRoute(
          path: '/articles',
          builder: (context, state) => _placeholder('Articles')),
    ],
  );
}
