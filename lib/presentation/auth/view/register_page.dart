import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fpdart/fpdart.dart' show Left, Right, TaskEither;
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/errors/exceptions/auth_exceptions.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/presentation/auth/controllers/auth_status_enum.dart';
import 'package:outnest/presentation/auth/controllers/handle_social_signin.dart';
import 'package:outnest/presentation/auth/view/components/apple_auth_button.dart';
import 'package:outnest/presentation/auth/view/components/auth_button.dart';
import 'package:outnest/presentation/auth/view/components/auth_input.dart';
import 'package:outnest/presentation/auth/view/components/google_auth_button.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';

// Yükleme durumlarını yönetmek için Enum

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneController = TextEditingController();

  // Enum değişkeni
  AuthStatus _authStatus = AuthStatus.none;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
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
        if (!mounted) return;
        await context.push(
          '/verification-code-field',
          extra: {
            'verificationID': sms.verificationId,
            'phoneNumber': '+90$rawNumber',
            'resendToken': sms.resendToken,
          },
        );
      case Left(value: OTPSendException()):
        if (!mounted) return;
        showErrorPopup(
          context,
          message: 'SMS gönderilemedi. Lütfen tekrar deneyiniz.',
        );
      case Left(value: SMSTimeoutException()):
        if (!mounted) return;
        showErrorPopup(
          context,
          message: 'Zaman aşımına uğradı. Lütfen tekrar deneyiniz.',
        );
      case Left(value: final _):
        if (!mounted) return;
        showErrorPopup(
          context,
          message: 'Beklenmedik bir hata oluştu.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Herhangi bir yükleme var mı kontrolü
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
              color: Colors.black,
              size: 24.sp,
            ),
            // Yükleme varsa geri tuşunu devre dışı bırak
            onPressed: isAnyLoading ? null : () => context.go('/welcome'),
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
                // Yükleme sırasında input submit'i engelle
                onSubmitted: isAnyLoading ? null : (_) => _handleSendCode(),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(14),
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
                text: _authStatus == AuthStatus.phone
                    ? 'Gönderiliyor...'
                    : 'gönder',
                // HATA ÇÖZÜMÜ: null yerine boş fonksiyon () {} veriyoruz
                onPressed: isAnyLoading ? () {} : _handleSendCode,
              ),
              SizedBox(height: 24.h),

              // AYRAÇ (VEYA)
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Text(
                      'veya',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12.sp,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              SizedBox(height: 24.h),

              // GOOGLE İLE KAYIT
              GoogleAuthButton(
                isLoading: _authStatus == AuthStatus.google,
                isDisabled: isAnyLoading,
                onTap: () async {
                  if (_authStatus != AuthStatus.none) return;
                  setState(() => _authStatus = AuthStatus.google);
                  await handleSocialSignIn(
                    context: context,
                    signIn: () =>
                        getIt<AuthService>().signInWithGoogle(isLogin: false),
                    providerName: 'Google',
                  );
                  if (mounted) setState(() => _authStatus = AuthStatus.none);
                },
              ),

              // APPLE İLE KAYIT (Sadece iOS ise)
              if (Platform.isIOS) ...[
                SizedBox(height: 12.h),
                AppleAuthButton(
                  isLoading: _authStatus == AuthStatus.apple,
                  isDisabled: isAnyLoading,
                  onTap: () async {
                    if (_authStatus != AuthStatus.none) return;
                    setState(() => _authStatus = AuthStatus.apple);
                    await handleSocialSignIn(
                      context: context,
                      signIn: () =>
                          getIt<AuthService>().signInWithApple(isLogin: false),
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

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Önce sadece rakamları al
    final text = newValue.text.replaceAll(' ', '');

    if (text.isEmpty) return newValue;

    // 2. Eğer 10 karakterden uzunsa kes (güvenlik)
    final truncatedText = text.length > 10 ? text.substring(0, 10) : text;

    final buffer = StringBuffer();
    for (var i = 0; i < truncatedText.length; i++) {
      buffer.write(truncatedText[i]);
      // 2., 5. ve 7. karakterden sonra boşluk ekle
      if (i == 2 || i == 5 || i == 7) {
        if (i != truncatedText.length - 1) {
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
