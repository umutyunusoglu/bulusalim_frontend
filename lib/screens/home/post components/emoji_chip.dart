import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmojiChip extends StatelessWidget {
  const EmojiChip({
    this.icon,
    this.emoji,
    required this.text,
    required this.color,
    this.isSelected = false,
    this.onTap,
    super.key,
  });

  final IconData? icon;
  final String? emoji;
  final String text;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Yarıçapı bir değişkene alalım ki hem dıştaki gölge kutusunda
    // hem de içteki kırpma işleminde aynı değeri kullanalım.
    final borderRadius = BorderRadius.circular(30.r);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // --- YENİ DIŞ KATMAN (GÖLGE İÇİN) ---
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius, // İçerideki yuvarlaklıkla aynı olmalı
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15), // Hafif siyah gölge
              blurRadius: 8.0, // Gölgenin yumuşaklığı (bulanıklığı)
              offset: const Offset(0, 4), // Gölgenin konumu (biraz aşağıda)
              spreadRadius: 0, // Gölgenin yayılma miktarı
            ),
          ],
        ),
        // --- ESKİ YAPI (İÇERİK VE BLUR) ---
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 30.h,
              constraints: BoxConstraints(
                minWidth: 60.w,
              ),
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.4)
                    : Colors.white.withOpacity(0.25),
                borderRadius: borderRadius,
                border: Border.all(
                  color: isSelected
                      ? color.withOpacity(0.8)
                      : Colors.white.withOpacity(0.1),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (emoji != null)
                    Text(
                      emoji!,
                      style: TextStyle(
                        fontSize: 18.sp,
                        height: 1.2,
                      ),
                    )
                  else if (icon != null)
                    Icon(
                      icon,
                      color: isSelected ? color : Colors.white,
                      size: 18.sp,
                    ),
                  SizedBox(width: 4.w),
                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Sf Pro Display',
                      fontWeight: FontWeight.w500,
                      fontSize: 18.sp,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
