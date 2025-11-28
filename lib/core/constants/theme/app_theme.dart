import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/core/constants/theme/text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  // --- LIGHT THEME ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true, // Modern görünüm
    fontFamily: 'Urbanist', // Tüm uygulama varsayılan fontu

    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.backgroundColor,

    // AppBar Ayarları
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.secondaryColor,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.onPrimaryColor),
      titleTextStyle: TextStyle(
        fontFamily: 'Urbanist',
        color: AppColors.onPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Text Temasını Bağlıyoruz
    textTheme: AppTextTheme.lightTextTheme,

    // Renk Şeması
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      surface: AppColors.backgroundColor,
      onPrimary: AppColors.onPrimaryColor,
      onSecondary: AppColors.onSecondaryColor,
      onSurface: AppColors.onBackgroundColor,
    ),

    // Input (TextField) Teması - Login ekranları için kritik
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(
        color: AppColors.onBackgroundColor.withOpacity(0.6),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
    ),

    // Buton Teması (kButtonBackgroundColor burada varsayılan oluyor)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            AppColors.slateBlue, // Senin istediğin mavi buton rengi
        foregroundColor: Colors.white, // Yazı rengi
        textStyle: AppTextTheme.lightTextTheme.labelLarge,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
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
      backgroundColor: AppColors.darkPrimaryColor,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.onPrimaryColor),
    ),

    textTheme: AppTextTheme.darkTextTheme,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimaryColor,
      secondary: AppColors.darkSecondaryColor,
      surface: AppColors.darkBackgroundColor,
      onPrimary: AppColors.onPrimaryColor,
      onSecondary: AppColors.darkOnSecondaryColor,
    ),

    // Dark Mode Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSecondaryColor.withOpacity(0.2),
      labelStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.darkPrimaryColor),
      ),
    ),

    // Dark Mode Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkSecondaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
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
