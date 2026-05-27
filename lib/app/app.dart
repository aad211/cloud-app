import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_app/app/router/app_router.dart';
import 'package:cloud_app/app/theme/app_theme.dart';
import 'package:cloud_app/core/widgets/mobile_frame.dart';

class CloudApp extends ConsumerStatefulWidget {
  const CloudApp({super.key, this.initialLocation});

  /// Optional override for the router's initial location; used in tests.
  final String? initialLocation;

  @override
  ConsumerState<CloudApp> createState() => _CloudAppState();
}

class _CloudAppState extends ConsumerState<CloudApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final guard = ref.read(onboardingGuardProvider);
    _router = buildRouter(
      onboardingGuard: guard,
      initialLocation: widget.initialLocation,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: buildAppTheme(),
      routerConfig: _router,
      builder:
          (context, child) =>
              MobileFrame(child: child ?? const SizedBox.shrink()),
    );
  }
}
