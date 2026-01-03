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
      child: Container(
        height: 22.h, // Yükseklik: 22px
        constraints: BoxConstraints(minWidth: 65.w), // Min Genişlik: 65px
        padding: EdgeInsets.only(
          left: 10.w,
          right: 10.w,
          top: 4.h, // Padding Top: 4px
          bottom: 4.h, // Padding Bottom: 4px
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20.r), // Radius: 20px
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
                height: 1.2, // Emojilerin kesilmemesi için biraz height
              ),
            ),
            SizedBox(width: 3.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w400, // Regular
                fontSize: 12.sp, // Size: 12px
                height: 1.0, // Line-height: 100%
                letterSpacing: 0,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
