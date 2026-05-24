import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/app/router/app_router.dart';
import 'package:ohok_flutter/app/theme/app_theme.dart';
import 'package:ohok_flutter/core/widgets/mobile_frame.dart';

class OhokApp extends StatefulWidget {
  const OhokApp({super.key});

  @override
  State<OhokApp> createState() => _OhokAppState();
}

class _OhokAppState extends State<OhokApp> {
  late final GoRouter _router = buildRouter();

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
