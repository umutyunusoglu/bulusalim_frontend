import 'package:bulusalim/components/auth_button.dart';
import 'package:bulusalim/components/otp_row.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({
    super.key,
    this.isLogin = false,
  });

  final bool isLogin;

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleVerify() {
    final otpCode = _controllers.map((e) => e.text).join();

    if (otpCode.length == 6) {
      // Not: Backend bağlandığında burada API isteği yapılacak.
      if (widget.isLogin) {
        context.go('/home'); // Giriş başarılıysa Home'a
      } else {
        context.push('/register-info'); // Kayıt ise bilgi formuna
      }
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
            onPressed: () {
              if (widget.isLogin) {
                context.go('/login');
              } else {
                context.go('/register');
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/outnest2.png',
                height: 48.h,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 80.h),
              Text(
                'Doğrulama Kodu',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 28.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: OtpRow(controllers: _controllers),
              ),
              SizedBox(height: 28.h),
              Text(
                'Telefonunuza gelen 6 haneli kodu giriniz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 76.h),
              AuthButton(
                text: widget.isLogin ? 'giriş yap' : 'gönder',
                onPressed: _handleVerify,
              ),
              SizedBox(height: 12.h),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'kodu tekrar gönder',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.tertiaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              SizedBox(height: 60.h),
            ],
          ),
        ),
      ),
    );
  }
}
