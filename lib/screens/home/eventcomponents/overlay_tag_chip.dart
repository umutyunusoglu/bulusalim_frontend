import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OverlayTagChip extends StatelessWidget {
  const OverlayTagChip({
    required this.label,
    required this.icon,
    super.key,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      // İç boşluk (Padding)
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      // Dış boşluk (Margin)
      margin: EdgeInsets.only(bottom: 6.h),

      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2), // Hafif karartma
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.tagBorder,
          width: 1.w,
        ),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14.sp,
          ),
          SizedBox(width: 4.w), // İkon ve metin arası boşluk
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
