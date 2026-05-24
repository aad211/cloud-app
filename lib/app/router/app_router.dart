import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/features/analysis/presentation/check_symptoms_screen.dart';
import 'package:ohok_flutter/features/history/presentation/history_screen.dart';
import 'package:ohok_flutter/features/home/presentation/home_screen.dart';
import 'package:ohok_flutter/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ohok_flutter/features/onboarding/presentation/splash_screen.dart';
import 'package:ohok_flutter/features/hospitals/presentation/hospitals_screen.dart';
import 'package:ohok_flutter/features/result/presentation/result_screen.dart';

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
          builder: (context, state) => const Scaffold(
              body: Center(child: Text('Articles and News')))),
    ],
  );
}
