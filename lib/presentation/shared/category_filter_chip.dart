import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

class CategoryFilterChip extends StatelessWidget {
  const CategoryFilterChip({
    required this.label,
    required this.emoji,
    this.isSelected = false,
    this.onTap,
    super.key,
  });

  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 22.h,
        constraints: BoxConstraints(minWidth: 30.w),
        padding: EdgeInsets.symmetric(
          horizontal: 8.w,
          vertical: 4.h,
        ),
        decoration: BoxDecoration(
          color: AppColors.inputFillColor,
          borderRadius: BorderRadius.circular(50.r),
          border: isSelected
              ? Border.all(
                  color: AppColors.tertiaryColor,
                  width: 1,
                )
              : Border.all(
                  color: Colors.transparent,
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: 11.sp,
                height: 1,
              ),
            ),
            SizedBox(width: 3.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w400,
                fontSize: 11.sp,
                height: 1,
                letterSpacing: 0,
                color: isSelected ? AppColors.tertiaryColor : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
