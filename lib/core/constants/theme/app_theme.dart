// lib/core/constants/theme/app_theme.dart

import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/core/constants/theme/text_theme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  // --- LIGHT THEME ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Urbanist', // Font burada tanımlı
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.backgroundColor,

    // AppBar Temiz ve Flat Görünüm
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.iconColor),
      titleTextStyle: TextStyle(
        fontFamily: 'Urbanist',
        color: AppColors.onBackgroundColor, // Başlık Siyah
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),

    textTheme: AppTextTheme.lightTextTheme,

    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryColor, // Action: Turuncu
      secondary: AppColors.secondaryColor, // Nav: Mavi
      tertiary: AppColors.tertiaryColor, // Deep Blue (#004B75)
      surface: AppColors.backgroundColor,
      onPrimary: AppColors.onPrimaryColor,
      onSecondary: AppColors.onSecondaryColor,
      onSurface: AppColors.onBackgroundColor, // Yazılar: Siyah
    ),

    // Input Alanı (Gri Kutu Tasarımı)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFillColor, // #F2F2F7
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: const TextStyle(color: AppColors.onBackgroundColor),
      hintStyle: TextStyle(color: AppColors.onBackgroundColor.withOpacity(0.5)),

      // Kenarlık Yok (Border Radius var)
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      // Odaklanınca Turuncu Çerçeve
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
      ),
    ),
  );

  // --- DARK THEME ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Urbanist',
    primaryColor: AppColors.darkPrimaryColor,
    scaffoldBackgroundColor: AppColors.darkBackgroundColor,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.darkOnBackgroundColor),
      titleTextStyle: TextStyle(
        fontFamily: 'Urbanist',
        color: AppColors.darkOnBackgroundColor,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),

    textTheme: AppTextTheme.darkTextTheme,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimaryColor, // Turuncu
      secondary: AppColors.darkSecondaryColor, // Mavi
      tertiary: AppColors.darkTertiaryColor, // Deep Blue Açık Ton
      surface: AppColors.darkBackgroundColor,
      onPrimary: AppColors.onPrimaryColor,
      onSecondary: AppColors.darkOnSecondaryColor,
      onSurface: AppColors.darkOnBackgroundColor, // Yazılar: Beyaz
    ),

    // Dark Input Alanı
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceColor, // Koyu Gri
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: const TextStyle(color: AppColors.darkOnBackgroundColor),
      hintStyle: TextStyle(
        color: AppColors.darkOnBackgroundColor.withOpacity(0.5),
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.darkPrimaryColor,
          width: 1.5,
        ),
      ),
    ),
  );
}
// // lib/core/constants/theme/app_theme.dart

// import 'package:bulusalim/core/constants/theme/color_themes.dart';
// import 'package:bulusalim/core/constants/theme/text_theme.dart';
// import 'package:flutter/material.dart';

// class AppTheme {
//   static final ThemeData lightTheme = ThemeData(
//     primaryColor: AppColors.primaryColor,
//     scaffoldBackgroundColor: AppColors.backgroundColor,
//     appBarTheme: const AppBarTheme(
//       backgroundColor: AppColors.secondaryColor,
//       iconTheme: IconThemeData(color: AppColors.onPrimaryColor),
//       titleTextStyle: TextStyle(
//         color: AppColors.onPrimaryColor,
//         fontSize: 20,
//       ),
//     ),
//     textTheme: AppTextTheme.lightTextTheme,
//     colorScheme: const ColorScheme.light(
//       primary: AppColors.primaryColor,
//       secondary: AppColors.secondaryColor,
//       surface: AppColors.backgroundColor,
//       //
//       // ignore: avoid_redundant_argument_values
//       onPrimary: AppColors.onPrimaryColor,
//       onSecondary: AppColors.onSecondaryColor,
//       onSurface: AppColors.onBackgroundColor,
//     ),

//     inputDecorationTheme: const InputDecorationTheme(
//       labelStyle: TextStyle(color: AppColors.onBackgroundColor),

//       enabledBorder: UnderlineInputBorder(
//         borderSide: BorderSide(
//           color: AppColors.onBackgroundColor,
//         ), // Default underline color
//       ),
//       focusedBorder: UnderlineInputBorder(
//         borderSide: BorderSide(color: AppColors.onBackgroundColor), // On focus
//       ),
//     ),
//   );

//   static final ThemeData darkTheme = ThemeData(
//     primaryColor: AppColors.darkPrimaryColor,
//     scaffoldBackgroundColor: AppColors.darkBackgroundColor,
//     appBarTheme: const AppBarTheme(
//       backgroundColor: AppColors.darkPrimaryColor,
//       iconTheme: IconThemeData(color: AppColors.onPrimaryColor),
//       titleTextStyle: TextStyle(
//         color: AppColors.onPrimaryColor,
//         fontSize: 20,
//       ),
//     ),
//     textTheme: AppTextTheme.darkTextTheme,
//     colorScheme: const ColorScheme.dark(
//       primary: AppColors.darkPrimaryColor,
//       secondary: AppColors.darkSecondaryColor,
//       //
//       // ignore: avoid_redundant_argument_values
//       surface: AppColors.darkBackgroundColor,
//       onPrimary: AppColors.onPrimaryColor,
//       onSecondary: AppColors.darkOnSecondaryColor,
//     ),
//   );
// }
