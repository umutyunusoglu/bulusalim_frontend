import 'package:flutter/services.dart';
import 'package:outnest/presentation/auth/view/components/auth_button.dart';
import 'package:outnest/presentation/auth/view/components/auth_input.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';

class RegisterStepView extends StatelessWidget {
  const RegisterStepView({
    required this.title,
    this.onNext,
    super.key,
    this.controller,
    this.hintText,
    this.description,
    this.enabled = true,
    this.buttonText = 'devam',
    this.keyboardType,
    this.inputFormatters,
    this.onSkip,
    this.customContent,
    this.readOnly = false,
    this.onTapInput,
    this.validator,
    this.onChanged,
    this.footerWidget,
  });

  final String title;
  final TextEditingController? controller;
  final VoidCallback? onNext;
  final String? hintText;
  final String? description;
  final bool enabled;
  final String buttonText;
  final TextInputType? keyboardType;
  final VoidCallback? onSkip;
  final Widget? customContent;
  final bool readOnly;
  final VoidCallback? onTapInput;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function()? validator;
  final Function(String)? onChanged; // Bunu ekle
  final Widget? footerWidget;

  void _handleNext(BuildContext context) {
    if (validator != null) {
      final error = validator!();
      if (error != null) {
        showErrorPopup(context, message: error);

        return;
      }
    }
    // Hata yoksa veya validator tanımlanmamışsa ilerle.
    onNext?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final keyboardOpen = bottomInset > 0;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        bottom: bottomInset + 24.h,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!keyboardOpen) ...[
            Image.asset(
              'assets/outnest2.png',
              height: 48.h,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 80.h),
          ] else
            SizedBox(height: 20.h),
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
              onTap: enabled ? onTapInput : null,
              child: AbsorbPointer(
                absorbing: !enabled || readOnly,
                child: AuthInput(
                  controller: controller!,
                  onChanged: enabled ? onChanged : null, // Buraya bağla
                  hintText: hintText,
                  keyboardType: keyboardType,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => enabled ? _handleNext(context) : null,
                  enabled: enabled,
                  inputFormatters: inputFormatters,
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
          if (onNext != null)
            AuthButton(
              text: buttonText,
              onPressed: () => _handleNext(context),
            ),

          // ATLA BUTONU
          if (onSkip != null) ...[
            if (onNext != null) SizedBox(height: 16.h),
            Container(
              width: 100.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
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

          if (footerWidget != null) ...[
            SizedBox(height: 16.h),
            footerWidget!,
          ],

          SizedBox(height: 60.h),
        ],
      ),
    );
  }
}
