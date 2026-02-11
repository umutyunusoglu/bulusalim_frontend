import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

class PopupNextButton extends StatelessWidget {
  const PopupNextButton({
    required this.onPressed,
    this.text = 'İlerle',
    super.key,
  });

  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 173.w,
      height: 40.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          // Aktif Renkler
          backgroundColor: AppColors.popupBtnBackground,
          foregroundColor: AppColors.popupBtnText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          // Pasif (Disabled) Renkler
          disabledBackgroundColor: Colors.grey[200],
          disabledForegroundColor: Colors.grey[400],
          padding: EdgeInsets.zero,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
