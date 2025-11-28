import 'package:bulusalim/components/tab_item.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final tabCount = tabs.length;

        // Güvenlik: Tab sayısı 0 ise boş dön
        if (tabCount == 0) {
          return const SizedBox.shrink();
        }

        final tabWidth = totalWidth / tabCount;
        final indicatorWidth = (tabWidth * 0.6).clamp(40.w, 140.w);

        // Güvenlik: Index sınırlarını koru
        final safeIndex = currentIndex.clamp(0, tabCount - 1);
        final leftOffset =
            safeIndex * tabWidth + (tabWidth - indicatorWidth) / 2;

        // Boyutlandırma
        final double indicatorHeight = 4.h;
        final double gradientSpread = 8.h;
        final double totalStackHeight = indicatorHeight + gradientSpread;

        return Column(
          children: [
            Row(
              children: List.generate(
                tabCount,
                (index) => TabItem(
                  label: tabs[index],
                  isSelected: currentIndex == index,
                  width: tabWidth,
                  onTap: () => onTabSelected(index),
                ),
              ),
            ),
            SizedBox(height: 8.h),

            // --- GÖSTERGE VE GÖLGE ALANI ---
            SizedBox(
              height: totalStackHeight,
              child: Stack(
                children: [
                  // 1. Alt Gölge (Gradient)
                  Positioned(
                    top: indicatorHeight,
                    child: Container(
                      height: gradientSpread,
                      width: totalWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.grey.withOpacity(0.6),
                            Colors.grey.shade300,
                          ],
                          stops: const [0.0, 0.9],
                        ),
                      ),
                    ),
                  ),

                  // 2. Mavi Hareketli Gösterge
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    left: leftOffset,
                    top: 0,
                    child: Container(
                      width: indicatorWidth,
                      height: indicatorHeight,
                      decoration: BoxDecoration(
                        color: AppColors.navyBlue,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
