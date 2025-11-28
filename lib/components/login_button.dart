import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// LoginButton artık bir StatefulWidget'tır
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
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? width;

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> {
  @override
  Widget build(BuildContext context) {
    final resolvedBorderColor = widget.borderColor ?? AppColors.slateBlue;

    return GestureDetector(
      onTap: widget.onPress,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: resolvedBorderColor,
            width: widget.borderWidth,
          ),
        ),

        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            onTap: widget.onPress,
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor ?? AppColors.slateBlue,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Urbanist',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
