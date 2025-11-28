import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextTheme {
  static const String fontFamily = 'Urbanist';

  // --- LIGHT THEME TEXTS ---
  static TextTheme get lightTextTheme => TextTheme(
    // Büyük Başlıklar (Örn: Sayfa Başlıkları)
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32.sp,
      fontWeight: FontWeight.w700,
      color: AppColors.onBackgroundColor,
    ),

    // Orta Başlıklar
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.onBackgroundColor,
    ),

    // (Eski: kLoginTextStyle) -> Giriş ekranı başlığı ve kart başlıkları
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 20.sp,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),

    // Gövde Metni (Post açıklamaları vb.)
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14.sp,
      fontWeight: FontWeight.normal,
      color: AppColors.onBackgroundColor,
    ),

    // (Eski: kSkipButtonText) -> Buton üzerindeki yazılar
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 15.sp,
      fontWeight: FontWeight.w600, // Butonlar genelde biraz kalın olur
      color: AppColors.navyBlue, // Senin istediğin lacivert renk
    ),

    // (Eski: kInfoIconTextStyle) -> Etiketler, Tarih, küçük ikon altı yazılar
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 10.sp,
      fontWeight: FontWeight.w600,
      color: Colors.white, // Dikkat: Sadece koyu zemin üstünde okunur
    ),
  );

  // --- DARK THEME TEXTS ---
  static TextTheme get darkTextTheme => TextTheme(
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32.sp,
      fontWeight: FontWeight.w700,
      color: AppColors.darkOnBackgroundColor,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.darkOnBackgroundColor,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 20.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.darkOnBackgroundColor,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14.sp,
      fontWeight: FontWeight.normal,
      color: AppColors.darkOnBackgroundColor,
    ),
    // Dark mode'da lacivert okunmaz, beyaz yapıyoruz
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 15.sp,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 10.sp,
      fontWeight: FontWeight.w600,
      color: Colors.white70,
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
