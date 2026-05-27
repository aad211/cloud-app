import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_app/app/theme/app_colors.dart';
import 'package:cloud_app/core/storage/local_storage_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _navTimer;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    final pulseCurve = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.97, end: 1).animate(pulseCurve);
    _opacityAnimation = Tween<double>(begin: 0.92, end: 1).animate(pulseCurve);
    _navTimer = Timer(const Duration(seconds: 2), () async {
      final completed =
          await ref
              .read(localStorageServiceProvider)
              .getHasCompletedOnboarding();
      if (!mounted) return;
      context.go(completed ? '/home' : '/onboarding');
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud, size: 120, color: Colors.white),
                  SizedBox(height: 24),
                  Text(
                    'CLOUD',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Cough Lung Observation\n& Diagnosis',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.5,
                      color: Color(0xFFF4F8FB),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
