import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
    this.title,
    this.trailing,
    this.padding,
  });

  final Widget? title; // Ortadaki logo veya başlık
  final Widget? trailing; // Sağdaki ikon (örneğin bildirim)
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    // TEMA BAĞLANTISI
    final theme = Theme.of(context);

    final iconColor = theme.colorScheme.secondary;

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
          SizedBox(width: 30.w),

          // Ortada logo veya başlık
          Expanded(
            child: Center(
              child:
                  title ??
                  Image.asset(
                    'assets/bulusalim.png',
                    height: 40.h,
                    // Opsiyonel: Dark modda logonun rengi değişmesi gerekiyorsa
                    // color: theme.brightness == Brightness.dark ? Colors.white : null,
                  ),
            ),
          ),

          // Sağdaki ikon
          trailing ??
              Icon(
                Icons.notifications_none_outlined,
                color: iconColor,
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
