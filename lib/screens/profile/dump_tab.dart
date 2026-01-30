import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

class ProfileDumpTab extends StatelessWidget {
  const ProfileDumpTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //  İkon
            Icon(
              Icons.auto_awesome_motion_outlined,
              size: 48.sp,
              color: AppColors.tertiaryColor.withOpacity(0.7),
            ),
            SizedBox(height: 16.h),

            //Açıklama Metni
            Text(
              "Dump'ın Hazırlanıyor... Fotoğraf paylaşmaya devam et, ay sonunda sonucunu gör.",
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: theme.hintColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
