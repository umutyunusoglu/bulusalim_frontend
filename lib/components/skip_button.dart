import 'package:bulusalim/core/constants/theme/color_themes.dart'; // Renklerimizi buradan çekiyoruz
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SkipButton extends StatelessWidget {
  const SkipButton({
    required this.onTap,
    required this.text,
    super.key,
    this.backgroundColor = Colors.transparent,
    this.textColor,
    this.padding,
    this.hasBorder = false,
  });

  final String text;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effectiveTextColor = textColor ?? AppColors.slateBlue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            padding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(
            20.r,
          ),
          border: hasBorder
              ? Border.all(
                  color: effectiveTextColor.withOpacity(0.5),
                  width: 1,
                )
              : null,
        ),
        child: Text(
          text,

          style: theme.textTheme.labelLarge?.copyWith(
            color: effectiveTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}
