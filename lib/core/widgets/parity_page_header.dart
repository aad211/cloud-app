import 'package:flutter/material.dart';
import 'package:cloud_flutter/app/theme/app_colors.dart';

class ParityPageHeader extends StatelessWidget {
  const ParityPageHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
  });

  final String title;
  final VoidCallback onBack;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.sand,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.navy,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              splashRadius: 20,
              tooltip: 'Back',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(color: AppColors.blue, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
