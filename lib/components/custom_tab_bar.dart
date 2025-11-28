import 'package:bulusalim/components/tab_item.dart';
import 'package:bulusalim/core/constants/constant.dart';
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

        // Hata Çözümü: Sıfıra bölme kontrolü
        if (tabCount == 0) {
          return const SizedBox.shrink();
        }

        final tabWidth = totalWidth / tabCount;
        final indicatorWidth = (tabWidth * 0.6).clamp(40.w, 140.w);

        // currentIndex güvenliği
        final safeIndex = currentIndex.clamp(0, tabCount - 1);
        final leftOffset =
            safeIndex * tabWidth + (tabWidth - indicatorWidth) / 2;

        // Mavi çubuğun yüksekliği
        final double indicatorHeight = 4.h;
        // Gradient gölgenin yayılacağı alanın yüksekliği
        final double gradientSpread = 8.h;

        // Stack'in toplam yüksekliği: Çubuk + Gölge
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

            // --- YAPI GÜNCELLEMESİ: Stack dışarıdan SizedBox ile boyutlandırılıyor ---
            SizedBox(
              height: totalStackHeight,
              child: Stack(
                children: [
                  // 1. GRADIENT GÖLGE (FULL WIDTH)
                  Positioned(
                    top:
                        indicatorHeight, // Mavi çubuğun hemen altından başlar (4.h)
                    child: Container(
                      height: gradientSpread, // 8.h
                      width: totalWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.grey.withOpacity(0.6), // Üstte koyu gölge
                            Colors.grey.shade300, // Altta açık gölge
                          ],
                          stops: const [0.0, 0.9],
                        ),
                      ),
                    ),
                  ),

                  // 2. MAVİ GÖSTERGE (Üstte)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    left: leftOffset,
                    top: 0, // Stack'in en tepesine oturur.
                    child: Container(
                      width: indicatorWidth,
                      height: indicatorHeight,
                      decoration: BoxDecoration(
                        color: kBlueColor,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // --- YAPI GÜNCELLEME SONU ---
          ],
        );
      },
    );
  }
}
// import 'package:bulusalim/components/tab_item.dart';
// import 'package:bulusalim/core/constants/constant.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class CustomTabBar extends StatelessWidget {
//   const CustomTabBar({
//     required this.currentIndex,
//     required this.tabs,
//     required this.onTabSelected,
//     super.key,
//   });
//   final int currentIndex;
//   final List<String> tabs;
//   final void Function(int) onTabSelected;

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final totalWidth = constraints.maxWidth;
//         final tabCount = tabs.length;
//         final tabWidth = totalWidth / tabCount;
//         final indicatorWidth = (tabWidth * 0.6).clamp(40.w, 140.w);
//         final leftOffset =
//             currentIndex * tabWidth + (tabWidth - indicatorWidth) / 2;

//         return Column(
//           children: [
//             Row(
//               children: List.generate(
//                 tabCount,
//                 (index) => TabItem(
//                   label: tabs[index],
//                   isSelected: currentIndex == index,
//                   width: tabWidth,
//                   onTap: () => onTabSelected(index),
//                 ),
//               ),
//             ),
//             SizedBox(height: 8.h),
//             Stack(
//               children: [
//                 Container(
//                   height: 3.5.h,
//                   decoration: const BoxDecoration(
//                     color: Colors.transparent,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.transparent,
//                         offset: Offset(0, 2),
//                         blurRadius: 4,
//                         spreadRadius: 1,
//                       ),
//                     ],
//                   ),
//                 ),
//                 AnimatedPositioned(
//                   duration: const Duration(milliseconds: 260),
//                   curve: Curves.easeInOut,
//                   left: leftOffset,
//                   top: 0,
//                   child: Container(
//                     width: indicatorWidth,
//                     height: 3.h,
//                     decoration: BoxDecoration(
//                       color: kBlueColor,
//                       borderRadius: BorderRadius.circular(10.r),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
