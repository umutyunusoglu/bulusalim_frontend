import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
    this.title,
    this.trailing,
    this.padding,
  });

  final Widget? title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 15.h,
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol taraf boşluk (Görsel denge için sağdaki ikon kadar yer kaplar)
          SizedBox(width: 30.w),

          // Ortada Logo veya Başlık
          Expanded(
            child: Center(
              child:
                  title ??
                  Image.asset(
                    'assets/bulusalim.png',
                    height: 40.h,
                  ),
            ),
          ),

          // Sağdaki İkon
          trailing ??
              Icon(
                Icons.notifications_none_outlined,
                color: AppColors.navyBlue,
                size: 28.sp,
              ),
        ],
      ),
    );
  }
}
