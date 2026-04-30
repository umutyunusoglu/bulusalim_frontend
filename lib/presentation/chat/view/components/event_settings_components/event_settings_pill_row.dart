import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EventSettingsPillRow extends StatelessWidget {
  const EventSettingsPillRow({
    super.key,
    required TextStyle labelStyle,
    required this.title,
    required this.value,
    this.icon,
    this.onTap,
    this.showTrailing = false,
  }) : _labelStyle = labelStyle;

  final TextStyle _labelStyle;
  final String title;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: _labelStyle),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              constraints: BoxConstraints(maxWidth: 240.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFDDEFF5),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14.sp, color: const Color(0xFF4A6572)),
                    SizedBox(width: 6.w),
                  ],
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  if (showTrailing) ...[
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.keyboard_arrow_right,
                      size: 18.sp,
                      color: const Color(0xFF4A6572),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
