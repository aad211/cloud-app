import 'package:flutter/material.dart';

import 'app_colors.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      secondary: AppColors.blue,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.sand,
    useMaterial3: true,
  );
}
