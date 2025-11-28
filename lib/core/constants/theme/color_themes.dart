import 'package:flutter/material.dart';

abstract class AppColors {
  // --- Ana Marka Renkleri (Mevcut Kırmızı Teman) ---
  static const Color primaryColor = Color(0xFFF52837);
  static const Color secondaryColor = Color(0xFFA62828);
  static const Color backgroundColor = Color(0xFFFAFAFA);

  // --- Yazı/İkon Renkleri (Light Mode) ---
  static const Color onPrimaryColor = Colors.white;
  static const Color onSecondaryColor = Colors.black87;
  static const Color onBackgroundColor = Color(0xFF2B2A2A);

  // --- Yeni Eklediğin Mavi/Slate Paleti (Etkinlik ve Post Kartları İçin) ---
  static const Color slateBlue = Color(0XFF5B7A98);
  static const Color navyBlue = Color(0xFF25396F);
  static const Color tagBorder = Color(0xFFFCAD9F);

  // --- KAMERA SAYFASI ÖZEL RENKLERİ ---
  // Buradaki turuncu rengi koruduk ve isimlendirdik
  static const Color customOrange = Color(0xFFF27A5E);

  // --- Koyu Tema (Dark Mode) Renkleri ---
  static const Color darkPrimaryColor = Color(0xFF2D1F1F);
  static const Color darkSecondaryColor = Color(0xFF555555);
  static const Color darkBackgroundColor = Color(0xFF1B1B1B);

  static const Color darkOnBackgroundColor = Color(0xFFE0E0E0);
  static const Color darkOnSecondaryColor = Color(0xFFD9D9D9);
}
