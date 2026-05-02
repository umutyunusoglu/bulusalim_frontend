import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EventSettingsSimpleActionRow extends StatelessWidget {
  const EventSettingsSimpleActionRow({
    required TextStyle labelStyle,
    required this.title,
    super.key,
    this.textColor,
    this.onTap,
  }) : _labelStyle = labelStyle;

  final TextStyle _labelStyle;
  final String title;
  final Color? textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Text(
          title,
          style: _labelStyle.copyWith(
            color: textColor ?? Colors.black87,
            fontWeight: textColor != null ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
