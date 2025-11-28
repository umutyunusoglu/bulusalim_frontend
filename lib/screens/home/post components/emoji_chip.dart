import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Emoji Çipi (PostCard üzerindeki overlay etkileşimler için)
class EmojiChip extends StatelessWidget {
  const EmojiChip({
    required this.icon,
    required this.text,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          0.3,
        ), // Arka plan (Glassmorphism etkisi)
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14.sp),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}
