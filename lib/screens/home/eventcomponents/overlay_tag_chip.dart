import 'package:bulusalim/core/constants/constant.dart';
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      margin: EdgeInsets.only(bottom: 6.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(
          0.2,
        ), //
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: kTagBorderColor, width: 1.w),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 14.sp),
          SizedBox(width: 2.w),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }
}
