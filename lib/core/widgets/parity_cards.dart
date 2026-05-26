import 'package:flutter/material.dart';
import 'package:cloud_flutter/app/theme/app_colors.dart';

class ParityGradientCard extends StatelessWidget {
  const ParityGradientCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1A3263),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ParityInfoCard extends StatelessWidget {
  const ParityInfoCard({
    super.key,
    required this.leading,
    required this.child,
    this.backgroundColor = AppColors.infoBackground,
  });

  final Widget leading;
  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [leading, const SizedBox(width: 12), Expanded(child: child)],
      ),
    );
  }
}

class ParityDisclaimerCard extends StatelessWidget {
  const ParityDisclaimerCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.disclaimerBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.warning, fontSize: 12),
      ),
    );
  }
}
