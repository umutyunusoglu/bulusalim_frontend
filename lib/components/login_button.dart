import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  const LoginButton({
    super.key,
    required this.label,
    required this.onPress,
    required this.height,
    required this.width,
    required this.borderRadius,
    required this.borderWidth,

    this.backgroundColor,
    this.textColor,
    this.borderColor,

    this.fontSize = 18.0,
    this.fontWeight = FontWeight.w700,
  });

  final String label;
  final VoidCallback onPress;
  final double height;
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
    final theme = Theme.of(context);

    // Renkler null gelirse varsayılan tema renklerini kullan
    final defaultColor = theme.colorScheme.secondary;

    final effectiveBackgroundColor = backgroundColor ?? Colors.white;
    final effectiveBorderColor = borderColor ?? defaultColor;
    final effectiveTextColor = textColor ?? defaultColor;

    return SizedBox(
      height: height,
      width: width,
      child: Material(
        color: effectiveBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(
            color: effectiveBorderColor,
            width: borderWidth,
          ),
        ),
        child: InkWell(
          onTap: onPress,
          borderRadius: BorderRadius.circular(borderRadius),
          // Tıklama efekti rengi
          splashColor: effectiveTextColor.withOpacity(0.1),
          highlightColor: effectiveTextColor.withOpacity(0.05),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Urbanist',
                color: effectiveTextColor,
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
