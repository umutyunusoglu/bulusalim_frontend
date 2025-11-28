import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InfoIconText extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const InfoIconText({
    Key? key,
    required this.icon,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 12.sp),
        SizedBox(width: 6.w),
        child,
      ],
    );
  }
}
