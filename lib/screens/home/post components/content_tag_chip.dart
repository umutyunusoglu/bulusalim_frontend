import 'package:bulusalim/core/constants/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// İçerik Etiketi Çipi
class ContentTagChip extends StatelessWidget {
  const ContentTagChip({required this.label, required this.icon, super.key});
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
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: kBlueColor,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: kBlueColor,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
