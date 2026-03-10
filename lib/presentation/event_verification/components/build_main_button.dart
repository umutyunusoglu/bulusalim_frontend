// Ortak Buton
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

Widget buildMainButton(String text, VoidCallback onPressed) {
  return Container(
    width: double.infinity,
    height: 55,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [
        BoxShadow(
          color: AppColors.darkSurfaceColor,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkSlate,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.backgroundColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
