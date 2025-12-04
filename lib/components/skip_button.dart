import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SkipButton extends StatelessWidget {
  const SkipButton({
    required this.onTap,
    required this.text,
    super.key,
    this.color,
  });

  final String text;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.tertiary;

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        foregroundColor: effectiveColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Urbanist',
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: effectiveColor,
        ),
      ),
    );
  }
}
