import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MapFilterChip extends StatelessWidget {
  const MapFilterChip({
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
          // Arka plan her zaman beyaz (veya isteğe göre gri)
          color: const Color(0XFFF2F2F7),
          borderRadius: BorderRadius.circular(20.r),

          // Seçiliyse 1px Siyah Border, değilse Transparent (görünmez)
          border: isSelected
              ? Border.all(width: 1)
              : Border.all(
                  color: Colors.transparent,
                ), // Zıplamayı önlemek için width tutuyoruz

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                fontSize: 12.sp,
                height: 1,
              ),
            ),
            SizedBox(width: 3.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w400,
                fontSize: 12.sp,
                height: 1,
                letterSpacing: 0,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
