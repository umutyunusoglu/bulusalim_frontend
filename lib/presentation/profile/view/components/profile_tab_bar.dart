import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';

class ProfileTabBar extends StatelessWidget {
  const ProfileTabBar({
    required this.currentIndex,
    required this.onTabSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    // --- TEMA BAĞLANTISI ---
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Primary: Turuncu (Ortadaki ikon için)
    final primaryColor = theme.colorScheme.primary;
    // Secondary: Mavi (Kenardaki ikonlar için)
    final secondaryColor = theme.colorScheme.secondary;

    // Alt Çizgi Rengi Mantığı:
    // Eğer ortadaki sekme (index 1) seçiliyse çizgi Primary (Turuncu), değilse Secondary (Mavi) olsun.
    final currentIndicatorColor = currentIndex == 1
        ? primaryColor
        : secondaryColor;

    final icons = <IconData>[
      Symbols.view_cozy, // 0: Sol
      Symbols.location_on, // 1: Orta
      Symbols.view_apps, // 2: Sağ
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final tabCount = icons.length;

        if (tabCount == 0) return const SizedBox.shrink();

        final tabWidth = totalWidth / tabCount;

        // Çizgi genişliği (%70)
        final indicatorWidth = (tabWidth * 0.7).clamp(40.w, 80.w);

        final safeIndex = currentIndex.clamp(0, tabCount - 1);
        final leftOffset =
            safeIndex * tabWidth + (tabWidth - indicatorWidth) / 2;

        // Yükseklik Ayarları
        final indicatorHeight = 4.h;
        final gradientSpread = 8.h;
        final totalStackHeight = indicatorHeight + gradientSpread;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. İKONLAR
            SizedBox(
              height: 45.h,
              child: Row(
                children: List.generate(tabCount, (index) {
                  // --- İKON RENK KURALI (TEMA TABANLI) ---
                  Color iconColor;
                  if (index == 1) {
                    // Orta İkon -> Primary (Turuncu)
                    iconColor = primaryColor;
                  } else {
                    // Kenar İkonlar -> Secondary (Mavi)
                    iconColor = secondaryColor;
                  }

                  return SizedBox(
                    width: tabWidth,
                    child: InkWell(
                      onTap: () => onTabSelected(index),
                      customBorder: const CircleBorder(),
                      child: Icon(
                        icons[index],
                        color: iconColor,
                        size: 26.sp,
                      ),
                    ),
                  );
                }),
              ),
            ),

            SizedBox(height: 4.h),

            // 2. HAREKETLİ ALT ÇİZGİ
            SizedBox(
              height: totalStackHeight,
              child: Stack(
                children: [
                  // A) GÖLGE KATMANI
                  Positioned(
                    top: indicatorHeight - 2,
                    child: Container(
                      height: gradientSpread,
                      width: totalWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDarkMode
                              ? [
                                  Colors.black.withOpacity(0.5),
                                  Colors.transparent,
                                ]
                              : [
                                  Colors.grey.withOpacity(0.4),
                                  Colors.grey.withOpacity(0),
                                ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // B) HAREKETLİ RENKLİ ÇUBUK
                  AnimatedPositioned(
                    // OPTİMİZASYON: Daha hızlı ve akıcı geçiş (160ms + easeOutQuad)
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutQuad,
                    left: leftOffset,
                    top: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutQuad,
                      width: indicatorWidth,
                      height: indicatorHeight,
                      decoration: BoxDecoration(
                        color:
                            currentIndicatorColor, // Seçili renge göre değişir
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: currentIndicatorColor.withOpacity(0.3),
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
