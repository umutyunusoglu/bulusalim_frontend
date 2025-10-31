// lib/core/constants/theme/color_themes.dart

import 'package:flutter/material.dart';

// Blue - Beige Palette
//#1F748B    #2A97A6   #7FE4F3   #D9D3C2    #8B7A6A

abstract class AppColors {
  static const Color primaryColor = Color(0xFFF52837);
  static const Color secondaryColor = Color(0xFFA62828);
  static const Color backgroundColor = Color(0xFFEAE9D9);

  static const Color onPrimaryColor = Colors.white;
  static const Color onSecondaryColor = Colors.black87;
  static const Color onBackgroundColor = Color(0xFF2B2A2A);

  // Koyu tema renkleri
  static const Color darkPrimaryColor = Color.fromARGB(255, 27, 15, 15);
  static const Color darkSecondaryColor = Color(0xFF555555);
  static const Color darkBackgroundColor = Color.fromARGB(255, 190, 76, 76);

  static const Color darkOnBackgroundColor = Color.fromARGB(255, 151, 67, 67);
  static const Color darkOnSecondaryColor = Color.fromARGB(179, 48, 32, 32);
}
