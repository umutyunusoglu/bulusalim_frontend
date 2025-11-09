import 'package:bulusalim/core/constants/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Header extends StatelessWidget {
  final Widget? title; // ortadaki logo veya başlık
  final Widget? trailing; // sağdaki ikon (örneğin bildirim)
  final EdgeInsetsGeometry? padding;

  const Header({
    super.key,
    this.title,
    this.trailing,
    this.padding,
  });

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
          // sol taraf boşluk (görsel denge için)
          SizedBox(width: 30.w),

          // ortada logo veya başlık
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

          // sağdaki ikon
          trailing ??
              Icon(
                Icons.notifications_none_outlined,
                color: kBlueColor,
                size: 28.sp,
              ),
        ],
      ),
    );
  }
}

/*
// 🔝 Üst Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset('assets/bulusalim.png'),
                  SizedBox(width: 110.sp),
                  Icon(
                    Icons.notifications_none,
                    size: 25.sp,
                    color: kBlueColor,
                  ),
                ],
              ),*/
