import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTabBar extends StatelessWidget {
  const CustomTabBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTabSelected,
    super.key,
  });

  final int currentIndex;
  final List<String> tabs;
  final void Function(int) onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        // Elemanları (Senlik - Arkadaşların - Okul) eşit aralıkla yay
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(tabs.length, (index) {
          final isSelected = currentIndex == index;

          return GestureDetector(
            onTap: () => onTabSelected(index),
            // Tıklama alanını genişletmek için:
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Sadece içeriği kadar yer kapla
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. SEKME METNİ
                Text(
                  tabs[index],
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    // Renk: Seçiliyse Koyu Mavi, Değilse Gri
                    color: isSelected
                        ? AppColors.tertiaryColor
                        : const Color(0xFFC4C4C4),
                  ),
                ),

                // 2. ALT ÇİZGİ (Sadece seçili olanda görünür)
                if (isSelected) ...[
                  SizedBox(height: 4.h), // Yazı ile çizgi arası boşluk
                  Container(
                    width: 40.w, // Çizgi genişliği
                    height: 3.h, // Çizgi kalınlığı
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ] else ...[
                  SizedBox(height: 7.h),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}
