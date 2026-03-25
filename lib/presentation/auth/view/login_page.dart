import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fpdart/fpdart.dart' show Left, Right, TaskEither;
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/core/errors/exceptions/auth_exceptions.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/presentation/auth/controllers/auth_status_enum.dart';
import 'package:outnest/presentation/auth/controllers/handle_social_login.dart';
import 'package:outnest/presentation/auth/view/components/apple_auth_button.dart';
import 'package:outnest/presentation/auth/view/components/auth_button.dart';
import 'package:outnest/presentation/auth/view/components/auth_input.dart';
import 'package:outnest/presentation/auth/view/components/google_auth_button.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';
import 'package:outnest/presentation/shared/form/formatters/phone_input_formatter.dart';

// Yükleme durumlarını ayırt etmek için enum

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();

  // Hangi yöntemin işlemde olduğunu tutan değişken
  AuthStatus _authStatus = AuthStatus.none;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_authStatus != AuthStatus.none) return;

    final rawNumber = _phoneController.text.replaceAll(' ', '');

    if (rawNumber.isEmpty) {
      showErrorPopup(context, message: 'Lütfen telefon numaranızı giriniz.');
      return;
    }

    if (!rawNumber.startsWith('5')) {
      showErrorPopup(context, message: 'Telefon numarası 5 ile başlamalıdır.');
      return;
    }

    if (rawNumber.length != 10) {
      showErrorPopup(
        context,
        message: 'Lütfen numaranızı eksiksiz giriniz (10 hane).',
      );
      return;
    }

    setState(() => _authStatus = AuthStatus.phone);

    final result = await getIt<AuthService>()
        .sendSMS(phoneNumber: '+90$rawNumber')
        .run();

    if (!mounted) return;
    setState(() => _authStatus = AuthStatus.none);

    switch (result) {
      case Right(value: final sms):
        await context.push(
          '/login-verification',
          extra: {
            'verificationID': sms.verificationId,
            'phoneNumber': '+90$rawNumber',
            'resendToken': sms.resendToken,
          },
        );
      case Left(value: OTPSendException()):
        showErrorPopup(
          context,
          message: 'SMS gönderilemedi. Lütfen tekrar deneyiniz.',
        );
      case Left(value: SMSTimeoutException()):
        showErrorPopup(
          context,
          message: 'SMS zaman aşımına uğradı. Lütfen tekrar deneyiniz.',
        );
      case Left(value: final _):
        showErrorPopup(
          context,
          message: 'Beklenmedik bir hata oluştu.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Herhangi bir yükleme işlemi var mı?
    final isAnyLoading = _authStatus != AuthStatus.none;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Symbols.reply,
              weight: 400,
              color: Colors.black,
              size: 20.sp,
            ),
            //Todo:bug
            onPressed: isAnyLoading ? null : () => context.go('/welcome'),
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
                "Telefon Numarası'yla Giriş Yap",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 24.h),
              AuthInput(
                controller: _phoneController,
                hintText: '5XX XXX XX XX',
                prefixText: '+90',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                // Eğer yükleme varsa klavye submit'ini de engelle
                onSubmitted: isAnyLoading ? null : (_) => _handleLogin(),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(14),
                  PhoneInputFormatter(),
                ],
              ),
              SizedBox(height: 24.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Text(
                  'Outnest hesabına telefon numaranla güvenli bir şekilde bağlan. Giriş yapman için sana SMS ile hemen bir onay kodu göndereceğiz.\n\nDoğrulama kodu bu numaraya gönderilecektir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 36.h),

              // SMS GÖNDER BUTONU
              AuthButton(
                text: _authStatus == AuthStatus.phone
                    ? 'Gönderiliyor...'
                    : 'gönder',
                // Herhangi bir işlem varsa butonu devre dışı bırak
                onPressed: isAnyLoading ? null : _handleLogin,
              ),

              SizedBox(height: 24.h),

              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.grey.shade300, thickness: 1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Text(
                      'veya',
                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.grey.shade300, thickness: 1),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // GOOGLE BUTONU
              GoogleAuthButton(
                isLoading: _authStatus == AuthStatus.google,
                isDisabled: isAnyLoading,
                onTap: () async {
                  if (_authStatus != AuthStatus.none) return;
                  setState(() => _authStatus = AuthStatus.google);
                  await handleSocialLogin(
                    context: context,
                    signIn: () =>
                        getIt<AuthService>().signInWithGoogle(isLogin: true),
                    providerName: 'Google',
                  );
                  if (mounted) setState(() => _authStatus = AuthStatus.none);
                },
              ),

              if (Platform.isIOS) ...[
                SizedBox(height: 12.h),
                // APPLE BUTONU
                AppleAuthButton(
                  isLoading: _authStatus == AuthStatus.apple,
                  isDisabled: isAnyLoading,
                  onTap: () async {
                    if (_authStatus != AuthStatus.none) return;
                    setState(() => _authStatus = AuthStatus.apple);

                    await handleSocialLogin(
                      context: context,
                      signIn: () =>
                          getIt<AuthService>().signInWithApple(isLogin: true),
                      providerName: 'Apple',
                    );

                    if (mounted) setState(() => _authStatus = AuthStatus.none);
                  },
                ),
              ],
              SizedBox(height: 60.h),
            ],
          ),
        ),
      ),
    );
  }
}
