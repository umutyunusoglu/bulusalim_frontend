import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnnouncementButton extends StatelessWidget {
  const AnnouncementButton({
    super.key,
    this.onTap,
    this.height,
    this.width,
    this.iconColor,
    this.backgroundColor,
  });

  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          height: height ?? 32.h,
          width: width ?? 78.w,
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.transparent,
              width: 0,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.campaign_outlined,
              color: iconColor ?? theme.colorScheme.onSurface,
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }
}
