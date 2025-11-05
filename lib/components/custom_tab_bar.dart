import 'package:bulusalim/core/constants/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'tab_item.dart';

class CustomTabBar extends StatelessWidget {
  const CustomTabBar({
    super.key,
    required this.currentIndex,
    required this.tabs,
    required this.onTabSelected,
  });
  final int currentIndex;
  final List<String> tabs;
  final Function(int) onTabSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final tabCount = tabs.length;
        final tabWidth = totalWidth / tabCount;
        final indicatorWidth = (tabWidth * 0.6).clamp(40.w, 140.w);
        final leftOffset =
            currentIndex * tabWidth + (tabWidth - indicatorWidth) / 2;

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
            Stack(
              children: [
                Container(
                  height: 3.5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.4),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  left: leftOffset,
                  top: 0,
                  child: Container(
                    width: indicatorWidth,
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: kBlueColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
