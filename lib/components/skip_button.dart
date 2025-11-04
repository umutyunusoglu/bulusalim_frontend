import 'package:bulusalim/core/constants/constant.dart' as TextStyles;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SkipButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? backgroundColor;
  //final double borderRadius;
  final EdgeInsets padding;

  const SkipButton({
    super.key,
    required this.onTap,
    required this.text,
    this.backgroundColor = Colors.transparent,
    //this.borderRadius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          //border için
          /*
          borderRadius: BorderRadius.circular(borderRadius.r),
          border: Border.all(
            color: TextStyles.skipButtonText.color!.withOpacity(0.5),
            width: 1,
          ),*/
        ),
        child: Text(
          text,
          style: TextStyles.kSkipButtonText,
        ),
      ),
    );
  }
}
