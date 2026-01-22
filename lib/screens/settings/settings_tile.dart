import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.title,
    super.key,
    this.subtitle,
    this.trailingText,
    this.titleColor = Colors.black,
    this.showArrow = true,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? trailingText;
  final Color titleColor;
  final bool showArrow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      highlightColor: Colors.grey.withOpacity(0.1),
      splashColor: Colors.grey.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 10.sp,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingText != null)
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Text(
                  trailingText!,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 10.sp, // İsteğine göre fixlendi
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            if (showArrow)
              Icon(
                Icons.chevron_right,
                color: Colors.black,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }
}
