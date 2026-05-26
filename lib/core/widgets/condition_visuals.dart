import 'package:flutter/material.dart';
import 'package:cloud_flutter/app/theme/app_colors.dart';

class ConditionVisuals {
  const ConditionVisuals({required this.emoji, required this.color});

  final String emoji;
  final Color color;
}

ConditionVisuals conditionVisualsFor(String condition) {
  switch (condition) {
    case 'Healthy':
      return const ConditionVisuals(emoji: '✅', color: AppColors.success);
    case 'Asthma':
      return const ConditionVisuals(emoji: '🫁', color: AppColors.blue);
    case 'Bronchitis':
      return const ConditionVisuals(emoji: '🤒', color: AppColors.gold);
    case 'Pneumonia':
    case 'COVID-19':
      return const ConditionVisuals(emoji: '🦠', color: AppColors.danger);
    case 'Lung Cancer':
      return const ConditionVisuals(emoji: '⚠️', color: AppColors.critical);
    default:
      return const ConditionVisuals(emoji: '🫁', color: AppColors.blue);
  }
}
