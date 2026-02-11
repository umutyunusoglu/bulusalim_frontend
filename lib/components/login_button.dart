import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginButton extends StatelessWidget {
  const LoginButton({
    required this.label,
    required this.onPress,
    super.key,

    this.height,
    this.width,
    this.borderRadius = 40.0,
    this.borderWidth = 0.0,

    this.backgroundColor,
    this.textColor,
    this.borderColor,

    this.fontSize = 16.0,
    this.fontWeight = FontWeight.w700,
  });

  final String label;
  final VoidCallback onPress;
  final double? height;
  final double? width;
  final double borderRadius;
  final double borderWidth;

  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? const Color(0xFFF2F2F7);
    final effectiveTextColor = textColor ?? AppColors.primaryColor;
    final effectiveBorderColor = borderColor ?? Colors.transparent;

    final effectiveHeight = height ?? 40.h;
    // Eğer parametre gelmezse varsayılan sonsuz genişlik olsun
    final effectiveWidth = width ?? double.infinity;

    return SizedBox(
      height: effectiveHeight,
      width: effectiveWidth,
      child: Material(
        color: effectiveBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius.r),
          side: borderWidth > 0
              ? BorderSide(color: effectiveBorderColor, width: borderWidth)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onPress,
          borderRadius: BorderRadius.circular(borderRadius.r),
          splashColor: effectiveTextColor.withOpacity(0.1),
          highlightColor: effectiveTextColor.withOpacity(0.05),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                color: effectiveTextColor,
                fontSize: fontSize.sp,
                fontWeight: fontWeight,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
