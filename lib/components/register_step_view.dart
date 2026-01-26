import 'package:bulusalim/components/auth_button.dart';
import 'package:bulusalim/components/auth_input.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RegisterStepView extends StatelessWidget {
  const RegisterStepView({
    required this.title,
    required this.onNext,
    super.key,
    this.controller,
    this.hintText,
    this.description,
    this.buttonText = 'devam',
    this.keyboardType,
    this.onSkip,
    this.customContent,
    this.readOnly = false,
    this.onTapInput,
  });

  final String title;
  final TextEditingController? controller;
  final VoidCallback onNext;
  final String? hintText;
  final String? description;
  final String buttonText;
  final TextInputType? keyboardType;
  final VoidCallback? onSkip;
  final Widget? customContent;
  final bool readOnly;
  final VoidCallback? onTapInput;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // LOGO
          Image.asset(
            'assets/outnest2.png',
            height: 48.h,
            fit: BoxFit.contain,
          ),

          SizedBox(height: 80.h),

          // BAŞLIK
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 24.h),

          // İÇERİK
          if (customContent != null)
            customContent!
          else if (controller != null)
            GestureDetector(
              onTap: onTapInput,
              child: AbsorbPointer(
                absorbing: readOnly,
                child: AuthInput(
                  controller: controller!,
                  hintText: hintText,
                  keyboardType: keyboardType,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => onNext(),
                ),
              ),
            ),

          SizedBox(height: 24.h),

          // AÇIKLAMA METNİ
          if (description != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 10.sp,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            )
          else
            SizedBox(height: 14.h),

          SizedBox(height: 36.h),

          // DEVAM / GÖNDER BUTONU
          AuthButton(
            text: buttonText,
            onPressed: onNext,
          ),

          // ATLA BUTONU
          if (onSkip != null) ...[
            SizedBox(height: 16.h),
            Container(
              width: 100.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  20.r,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      0.10,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSkip,
                  borderRadius: BorderRadius.circular(30.r),
                  child: Center(
                    child: Text(
                      'atla',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16.sp,
                        color: AppColors.tertiaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          SizedBox(height: 60.h),
        ],
      ),
    );
  }
}
