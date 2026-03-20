import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

class PrivateAccountView extends StatelessWidget {
  const PrivateAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryColor,
                width: 3.w,
              ),
            ),
            child: Icon(
              Symbols.lock,
              size: 50.sp,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Gizli Hesap',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Bu hesap ile etkileşime geçebilmek için\ntakip etmelisin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }
}
