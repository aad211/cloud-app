import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/app/theme/app_colors.dart';
import 'package:ohok_flutter/core/storage/local_storage_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud, size: 120, color: AppColors.navy),
            SizedBox(height: 24),
            Text(
              'CLOUD',
              style: TextStyle(fontSize: 42, color: AppColors.navy),
            ),
            Text('Cough Lung Observation & Diagnosis'),
          ],
        ),
      ),
    );
  }
}
