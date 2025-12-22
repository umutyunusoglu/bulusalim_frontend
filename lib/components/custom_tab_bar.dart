import 'package:bulusalim/components/tab_item.dart';
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
    // TEMA BAĞLANTISI:
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final indicatorColor = theme.colorScheme.secondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final tabCount = tabs.length;

        if (tabCount == 0) return const SizedBox.shrink();

        final tabWidth = totalWidth / tabCount;
        final indicatorWidth = (tabWidth * 0.6).clamp(40.w, 140.w);

        final safeIndex = currentIndex.clamp(0, tabCount - 1);
        final leftOffset =
            safeIndex * tabWidth + (tabWidth - indicatorWidth) / 2;

        // Gölge ve Çubuk Yükseklik Ayarları
        final indicatorHeight = 4.h; // Mavi çubuğun kalınlığı
        final gradientSpread = 8.h; // Gölgenin aşağı yayılma mesafesi
        final totalStackHeight = indicatorHeight + gradientSpread;

        return Column(
          children: [
            // 1. TAB BUTONLARI
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

            // 2. GÖLGELİ VE ANİMASYONLU ALAN
            SizedBox(
              height: totalStackHeight,
              child: Stack(
                children: [
                  // A) GÖLGE KATMANI (Gradient Shadow)
                  // Mavi çubuğun altından aşağı doğru süzülen gölge
                  Positioned(
                    top: indicatorHeight - 1, // Çubuğun tam altından başlar
                    child: Container(
                      height: gradientSpread,
                      width: totalWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          // Light Mod: Gri gölge | Dark Mod: Siyah gölge (parlamayı önler)
                          colors: isDarkMode
                              ? [
                                  Colors.black.withOpacity(0.5),
                                  Colors.transparent,
                                ]
                              : [
                                  Colors.grey.withOpacity(0.4),
                                  Colors.grey.withOpacity(0.0),
                                ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // B) HAREKETLİ ÇUBUK (INDICATOR)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    left: leftOffset,
                    top: 0,
                    child: Container(
                      width: indicatorWidth,
                      height: indicatorHeight,
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: indicatorColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
