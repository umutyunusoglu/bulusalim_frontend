// lib/core/constants/theme/text_theme.dart

import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';

class AppTextTheme {
  // Light Tema Yazıları (Siyah Ağırlıklı)
  static const TextTheme lightTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.onBackgroundColor, // Siyah
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.onBackgroundColor,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.onBackgroundColor,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.onBackgroundColor,
    ),
  );

  // Dark Tema Yazıları (Beyaz Ağırlıklı)
  static const TextTheme darkTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.darkOnBackgroundColor, // Beyaz
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.darkOnBackgroundColor,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.darkOnBackgroundColor,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.darkOnBackgroundColor,
    ),
  );
}
// // lib/core/constants/theme/text_theme.dart

// import 'package:bulusalim/core/constants/theme/color_themes.dart';
// import 'package:flutter/material.dart';

// class AppTextTheme {
//   static const TextTheme lightTextTheme = TextTheme(
//     headlineLarge: TextStyle(
//       fontSize: 32,
//       fontWeight: FontWeight.w600,
//       color: AppColors.onBackgroundColor,
//     ),
//     headlineMedium: TextStyle(
//       fontSize: 28,
//       fontWeight: FontWeight.w600,
//       color: AppColors.onBackgroundColor,
//     ),
//   );

//   static const TextTheme darkTextTheme = TextTheme(
//     headlineLarge: TextStyle(
//       fontSize: 32,
//       fontWeight: FontWeight.w600,
//       color: AppColors.darkOnBackgroundColor,
//     ),
//     headlineMedium: TextStyle(
//       fontSize: 28,
//       fontWeight: FontWeight.w600,
//       color: AppColors.darkOnBackgroundColor,
//     ),
//   );
// }
