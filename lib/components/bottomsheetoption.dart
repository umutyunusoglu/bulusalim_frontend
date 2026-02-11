import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

class BottomSheetOption {
  BottomSheetOption({
    required this.icon,
    required this.text,
    required this.onTap,
    this.isDestructive = false,
  });
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isDestructive;
}

class CustomActionBottomSheet extends StatelessWidget {
  const CustomActionBottomSheet({
    required this.options,
    this.height,
    super.key,
  });

  final List<BottomSheetOption> options;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final baseTextStyle = TextStyle(
      fontFamily: 'SF Pro Display',
      fontWeight: FontWeight.w400,
      fontSize: 14.sp,
      height: 1,
      letterSpacing: 0,
      color: Colors.black87,
    );

    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.only(bottom: 36.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),

          // Gri Tutamaç (Handle)
          Container(
            width: 32.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          SizedBox(height: 24.h),

          ...options.map((option) {
            // 1. Önce varsayılan rengi belirleyelim (Siyah veya Turuncu)
            var itemColor = option.isDestructive
                ? AppColors.primaryColor
                : Colors.black87;

            // 2. Eğer metin "Haritada Gör" içeriyorsa rengi yeşille ezelim
            if (option.text.contains('Haritada Gör')) {
              itemColor = const Color(0xFF218B3C);
            }

            return Column(
              children: [
                InkWell(
                  onTap: () {
                    option.onTap();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 8.h,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option.icon,
                          size: 24.sp,
                          color: itemColor,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            option.text,
                            style: baseTextStyle.copyWith(
                              color: itemColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (option != options.last) SizedBox(height: 8.h),
              ],
            );
          }),
        ],
      ),
    );
  }
}
