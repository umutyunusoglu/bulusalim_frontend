import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
    this.trailing,
    this.middleWidget,
  });

  final Widget? trailing;
  final Widget? middleWidget;

  @override
  Widget build(BuildContext context) {
    final iconColor = AppColors.secondaryColor;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. LOGO
          SizedBox(
            width: 30.w,
            height: 30.w,
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
            ),
          ),

          // 2. BOŞLUK
          SizedBox(width: 33.w),
          SizedBox(
            width: 236.w,
            height: 45.h,
            child: Center(
              child: middleWidget ?? const SizedBox(),
            ),
          ),

          // 4. BOŞLUK
          SizedBox(width: 38.w),

          // 5. BİLDİRİM İKONU
          trailing ??
              SizedBox(
                width: 24.sp,
                height: 24.sp,
                child: InkWell(
                  onTap: () {},
                  child: Icon(
                    Icons.notifications_none_outlined,
                    color: iconColor,
                    size: 24.sp,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
