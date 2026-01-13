import 'package:flutter/material.dart';

abstract class AppColors {
  // --- LIGHT THEME MAIN ---
  static const Color primaryColor = Color(0xFFFE6348); // Turuncu (Action/Katıl)
  static const Color secondaryColor = Color(0xFF5B7A98); // Steel Blue
  static const Color tertiaryColor = Color(0xFF004B75); // Koyu Mavi

  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color onPrimaryColor = Colors.white;
  static const Color onSecondaryColor = Colors.white;
  static const Color onBackgroundColor = Color(0xFF1A1A1A); // Ana Metin Rengi

  static const Color inputFillColor = Color(0xFFF2F2F7); // Input Arka Planları
  static const Color iconColor = Color(0xFF1A1A1A);
  static const Color dividerColor = Color(0xFFEEEEEE); // Liste ayırıcılar için
  static const Color accordionBackground = Color(
    0xFFF3F4F6,
  ); // Accordion zemini
  static const Color successGreen = Color(0xFF4CAF50); // Onay butonu

  // MyEventsPage (Buluşmalarım) Özel Renkleri
  static const Color darkSlate = Color(0xFF264653); // Başlık ve Aktif Tab Rengi
  static const Color lightCloud = Color(0xFFF0F3F5); // Tab Arka Plan Rengi
  static const Color salmonPink = Color(0xFFEABFB9); // Empty State ve İkonlar
  static const Color textGrey = Colors.grey; // Genel gri yazılar

  // --- POPUP & WIZARD COLORS  ---
  // "İlerle" butonu ve seçim ekranları için
  static const Color popupBtnBackground = Color(0xFFFFCCBC); // Pastel Turuncu
  static const Color popupBtnText = Color(0xFFBF360C); // Koyu Turuncu
  static const Color popupSurface = Colors.white; // Popup zemini

  // --- EVENT CARD COLORS ---
  static const Color cardBackgroundColor = Color(0xFFF2F2F7);
  static const Color locationBadgeBackground = Color(0xFFC0D0E0);
  static const Color locationBadgeText = Color(0xFF2A4E6C);
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
