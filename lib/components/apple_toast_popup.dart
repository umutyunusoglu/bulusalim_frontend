import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showAppleToast(
  ScaffoldMessengerState messenger,
  String message, {
  bool isError = false,
}) {
  messenger.showSnackBar(
    SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 3),
      margin: EdgeInsets.only(
        bottom: 50.h, // Bottom bar'ın biraz üstünde durması için
        left: 32.w,
        right: 32.w,
      ),
      content: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          // Blur efekti hissi için hafif transparan ve koyu bir ton
          color: const Color(0xFF1C1C1E).withOpacity(0.9),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: isError
                  ? const Color(0xFFFF453A)
                  : const Color(0xFF32D74B),
              size: 20.sp,
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
