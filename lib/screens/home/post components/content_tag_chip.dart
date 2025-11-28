import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// İçerik Etiketi Çipi (PostCard altında kullanılır)
class ContentTagChip extends StatelessWidget {
  const ContentTagChip({
    required this.label,
    required this.icon,
    super.key,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      margin: EdgeInsets.only(right: 6.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // İçerik kadar yer kaplasın
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: AppColors.navyBlue,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: AppColors.navyBlue,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
