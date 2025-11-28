// lib/core/constants/theme/text_theme.dart

import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';

class AppTextTheme {
  static const TextTheme lightTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: AppColors.onBackgroundColor,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.onBackgroundColor,
    ),
  );

  static const TextTheme darkTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: AppColors.darkOnBackgroundColor,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.darkOnBackgroundColor,
    ),
  );
}
