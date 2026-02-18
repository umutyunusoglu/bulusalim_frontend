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
    final borderRadius = BorderRadius.circular(30.r);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            // GÖLGE AYARI (YUMUŞATILDI):
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(
                      0.25,
                    ) // Eskiden 0.6 idi, şimdi çok hafif renk veriyor
                  : Colors.black.withOpacity(0.1),
              blurRadius: 8.0, // Gölgenin yayılması sınırlandı
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
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
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              decoration: BoxDecoration(
                // ARKA PLAN RENGİ (YUMUŞATILDI):
                // Seçiliyse: Çok hafif bir renk tonu atıyoruz (Tint)
                color: isSelected
                    ? color.withOpacity(
                        0.2,
                      ) // Eskiden 0.5 idi, şimdi daha cam gibi
                    : Colors.white.withOpacity(0.2),

                borderRadius: borderRadius,
                border: Border.all(
                  // Kenarlık rengini biraz belirgin tuttum ki şekil kaybolmasın
                  color: isSelected
                      ? color.withOpacity(0.5)
                      : Colors.white.withOpacity(0.15),
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
                        fontSize: 16.sp,
                        height: 1.2,
                      ),
                    )
                  else if (icon != null)
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 16.sp,
                    ),

                  SizedBox(width: 6.w),

                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'SF Pro Display',
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 14.sp,
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
