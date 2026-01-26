import 'package:bulusalim/components/auth_button.dart';
import 'package:bulusalim/components/auth_input.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSendCode() {
    final rawNumber = _phoneController.text.replaceAll(' ', '');
    debugPrint('Telefon Numarası: +90$rawNumber');

    // Sadece numara tam ise (10 hane) geçiş yap
    if (rawNumber.length == 10) {
      // --- DEĞİŞİKLİK BURADA ---
      // VerificationCodeField sayfasına yönlendiriyoruz
      context.push('/verification-code-field');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 24.sp,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // LOGO
              Image.asset(
                'assets/outnest2.png',
                height: 48.h,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    'outnest',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  );
                },
              ),

              SizedBox(height: 80.h),

              // BAŞLIK
              Text(
                'Telefon Numarası',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 24.h),

              // TELEFON INPUT
              AuthInput(
                controller: _phoneController,
                hintText: '5XX XXX XX XX',
                prefixText: '+90',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleSendCode(),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                  _PhoneInputFormatter(),
                ],
              ),

              SizedBox(height: 24.h),

              // BİLGİLENDİRME METNİ
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Text(
                  'Telefon numaran, hesabının güvenliğini sağlamak ve gerektiğinde seninle iletişime geçebilmek için kullanılır. Dilediğin zaman değiştirebilirsin.\n\nDoğrulama kodu bu numaraya gönderilecektir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ),

              SizedBox(height: 36.h),

              // GÖNDER BUTONU
              AuthButton(
                text: 'gönder',
                onPressed: _handleSendCode,
              ),
              SizedBox(height: 60.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 2 || i == 5 || i == 7) {
        if (i != text.length - 1) {
          buffer.write(' ');
        }
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
