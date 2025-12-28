// lib/core/constants/theme/color_themes.dart

import 'package:flutter/material.dart';

abstract class AppColors {
  // --- LIGHT THEME ---
  static const Color primaryColor = Color(0xFFFE6348); // Turuncu (Action/Katıl)
  static const Color secondaryColor = Color(0xFF5B7A98); // Steel Blue
  static const Color tertiaryColor = Color(0xFF004B75); // Koyu Mavi

  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color onPrimaryColor = Colors.white;
  static const Color onSecondaryColor = Colors.white;
  static const Color onBackgroundColor = Color(0xFF1A1A1A);

  static const Color inputFillColor = Color(0xFFF2F2F7);
  static const Color iconColor = Color(0xFF1A1A1A);

  // --- EVENT CARD COLORS (YENİ EKLENENLER) ---
  static const Color cardBackgroundColor = Color(0xFFF2F2F7);

  // Lokasyon Chip Renkleri
  static const Color locationBadgeBackground = Color(0xFFC0D0E0);
  static const Color locationBadgeText = Color(0xFF2A4E6C);

  // Info (Kişi/Saat) Chip Renkleri
  static const Color infoBadgeBackground = Color(0xFFE5E5EA);
  static const Color infoBadgeText = Colors.black;
  // --- DARK THEME ---
  static const Color darkPrimaryColor = Color(0xFFFE6348);
  static const Color darkSecondaryColor = Color(0xFF5B7A98);
  static const Color darkTertiaryColor = Color(0xFF8BA6BF);

  static const Color darkBackgroundColor = Color(0xFF1A1A1A);
  static const Color darkSurfaceColor = Color(0xFF2C2C2E);

  static const Color darkOnBackgroundColor = Color(0xFFFAFAFA);
  static const Color darkOnSecondaryColor = Colors.white;
}

// // lib/core/constants/theme/color_themes.dart

// import 'package:flutter/material.dart';

// // Blue - Beige Palette
// //#1F748B    #2A97A6   #7FE4F3   #D9D3C2    #8B7A6A

// abstract class AppColors {
//   static const Color primaryColor = Color(0xFFF52837);
//   static const Color secondaryColor = Color(0xFFA62828);
//   static const Color backgroundColor = Color(0xFFFAFAFA);

//   static const Color onPrimaryColor = Colors.white;
//   static const Color onSecondaryColor = Colors.black87;
//   static const Color onBackgroundColor = Color(0xFF2B2A2A);

//   // Koyu tema renkleri
//   static const Color darkPrimaryColor = Color.fromARGB(255, 27, 15, 15);
//   static const Color darkSecondaryColor = Color(0xFF555555);
//   static const Color darkBackgroundColor = Color.fromARGB(255, 190, 76, 76);

//   static const Color darkOnBackgroundColor = Color.fromARGB(255, 151, 67, 67);
//   static const Color darkOnSecondaryColor = Color.fromARGB(179, 48, 32, 32);
// }
