import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class Popup extends StatelessWidget {
  const Popup({
    required this.title,
    required this.description,
    required this.confirmButtonText,
    required this.onConfirm,
    this.cancelButtonText = 'vazgeç',
    this.confirmButtonColor,
    super.key,
  });
  final String title;
  final String description;
  final String confirmButtonText;
  final String cancelButtonText;
  final Color? confirmButtonColor;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // BAŞLIK
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
            SizedBox(height: 12.h),

            // AÇIKLAMA
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w400,
                fontSize: 10.sp,
                color: const Color(0xFF8E8E93),
                height: 1.4,
              ),
            ),
            SizedBox(height: 24.h),

            // BUTONLAR
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Butonları ortalar
              children: [
                // VAZGEÇ BUTONU
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 10.h,
                      horizontal: 20.w,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cancelButtonText,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),
                // ONAYLA BUTONU
                GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 10.h,
                      horizontal: 20.w,
                    ),
                    decoration: BoxDecoration(
                      color: confirmButtonColor ?? const Color(0xFF1F415B),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      confirmButtonText,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
