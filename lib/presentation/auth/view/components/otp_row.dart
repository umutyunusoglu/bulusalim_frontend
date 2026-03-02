import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:pinput/pinput.dart';

class OtpRow extends StatelessWidget {
  const OtpRow({
    required this.controllers,
    super.key,
  });

  final List<TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    // Mevcut tasarımındaki kutu stili
    final defaultPinTheme = PinTheme(
      width: 45.w,
      height: 45.h,
      textStyle: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F5),
        borderRadius: BorderRadius.circular(8.r),
      ),
    );

    return Pinput(
      length: 6,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(color: AppColors.darkPrimaryColor),
        ),
      ),
      // Mevcut controller listene veriyi aktarır (Uyumluluk için)
      onChanged: (value) {
        for (int i = 0; i < 6; i++) {
          if (i < value.length) {
            controllers[i].text = value[i];
          } else {
            controllers[i].text = '';
          }
        }
      },
      // Tüm hane dolunca klavyeyi kapat
      onCompleted: (pin) => FocusScope.of(context).unfocus(),
    );
  }
}
