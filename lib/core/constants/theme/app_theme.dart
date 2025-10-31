// lib/core/constants/theme/app_theme.dart

import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/core/constants/theme/text_theme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.secondaryColor,
      iconTheme: IconThemeData(color: AppColors.onPrimaryColor),
      titleTextStyle: TextStyle(
        color: AppColors.onPrimaryColor,
        fontSize: 20,
      ),
    ),
    textTheme: AppTextTheme.lightTextTheme,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      surface: AppColors.backgroundColor,
      //
      // ignore: avoid_redundant_argument_values
      onPrimary: AppColors.onPrimaryColor,
      onSecondary: AppColors.onSecondaryColor,
      onSurface: AppColors.onBackgroundColor,
    ),

    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: AppColors.onBackgroundColor),

      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.onBackgroundColor,
        ), // Default underline color
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.onBackgroundColor), // On focus
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: AppColors.darkPrimaryColor,
    scaffoldBackgroundColor: AppColors.darkBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkPrimaryColor,
      iconTheme: IconThemeData(color: AppColors.onPrimaryColor),
      titleTextStyle: TextStyle(
        color: AppColors.onPrimaryColor,
        fontSize: 20,
      ),
    ),
    textTheme: AppTextTheme.darkTextTheme,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimaryColor,
      secondary: AppColors.darkSecondaryColor,
      //
      // ignore: avoid_redundant_argument_values
      surface: AppColors.darkBackgroundColor,
      onPrimary: AppColors.onPrimaryColor,
      onSecondary: AppColors.darkOnSecondaryColor,
    ),
  );
}
