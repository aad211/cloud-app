import 'package:flutter/material.dart';

class MobileFrame extends StatelessWidget {
  const MobileFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useFrame = constraints.maxWidth > 430;
        final framedChild = ConstrainedBox(
          key: const Key('mobile-frame'),
          constraints: const BoxConstraints(maxWidth: 375, minHeight: 812),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: child,
          ),
        );

        if (!useFrame) {
          return child;
        }

        return Center(child: framedChild);
      },
    );
  }
}
