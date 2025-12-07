import 'package:flutter/material.dart';

class LoginButton extends StatefulWidget {
  const LoginButton({
    required this.label,
    required this.onPress,
    required this.height,
    required this.borderWidth,
    required this.borderRadius,
    required this.width,
    super.key,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  final String label;
  final VoidCallback onPress;
  final double height;
  final double borderWidth;
  final double borderRadius;
  final double? width;

  // Opsiyonel renkler
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> {
  @override
  Widget build(BuildContext context) {
    // TEMA BAĞLANTISI
    final theme = Theme.of(context);

    final defaultBlue = theme.colorScheme.secondary;

    final effectiveBorderColor = widget.borderColor ?? defaultBlue;
    final effectiveTextColor = widget.textColor ?? defaultBlue;
    final effectiveBackgroundColor = widget.backgroundColor ?? Colors.white;

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Material(
        color: effectiveBackgroundColor, // Zemin Rengi (Beyaz)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          side: BorderSide(
            color: effectiveBorderColor, // Kenarlık Rengi (Mavi)
            width: widget.borderWidth,
          ),
        ),
        child: InkWell(
          onTap: widget.onPress,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          // Tıklama efekti rengi (Hafif mavi dalgalanma)
          splashColor: effectiveTextColor.withOpacity(0.1),
          highlightColor: effectiveTextColor.withOpacity(0.05),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Urbanist',
                color: effectiveTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
