import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InfoIconText extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const InfoIconText({
    required this.icon,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 12.sp,
        ),
        SizedBox(
          width: 4.w,
        ),
        child,
      ],
    );
  }
}
