import 'dart:io';

import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/app_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/presentation/auth/view/components/auth_button.dart';
import 'package:outnest/presentation/auth/view/components/auth_input.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';

// Yükleme durumlarını yönetmek için Enum
enum AuthStatus { none, phone, google, apple }

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
    // Herhangi bir işlem sürüyorsa durdur
    if (_authStatus != AuthStatus.none) return;

    // 1. FORMATI TEMİZLE
    final rawNumber = _phoneController.text.replaceAll(' ', '');

    // 2. VALIDASYON KONTROLLERİ
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

    // Telefon işlemi başladı
    setState(() => _authStatus = AuthStatus.phone);

    try {
      final result = await getIt<AuthService>().sendSMS(
        phoneNumber: '+90$rawNumber',
      );

      if (mounted) {
        // Sonuç geldi, yüklemeyi durdur
        setState(() => _authStatus = AuthStatus.none);

        if (result.error != null) {
          showErrorPopup(
            context,
            message: 'Bir hata ile karşılaşıldı. Lütfen tekrar deneyiniz.',
          );
        } else {
          final verificationID = result.verificationId;
          final resendToken = result.resendToken;
          await context.push(
            '/verification-code-field',
            extra: {
              'verificationID': verificationID,
              'phoneNumber': '+90$rawNumber',
              'resendToken': resendToken,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _authStatus = AuthStatus.none);
        showErrorPopup(context, message: 'Beklenmedik bir hata oluştu.');
      }
      debugPrint('Beklenmedik hata: $e');
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
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: OutlinedButton.icon(
                  onPressed: isAnyLoading
                      ? null
                      : () async {
                          setState(() => _authStatus = AuthStatus.google);
                          try {
                            await getIt<AuthService>().signInWithGoogle(
                              isLogin: false,
                            );
                            if (mounted) context.push('/register-info');
                          } catch (e) {
                            if (mounted) {
                              setState(() => _authStatus = AuthStatus.none);
                              showErrorPopup(
                                context,
                                message:
                                    'Google ile giriş yaparken hata oluştu. Lütfen tekrar deneyiniz.',
                              );
                            }
                          }
                          // push işleminden geri dönülürse loading'i kapatmak için
                          // finally bloğu eklenebilir ancak görsel akış için
                          // şimdilik sadece hata durumunda resetliyoruz.
                        },
                  icon: _authStatus == AuthStatus.google
                      ? SizedBox(
                          height: 22.h,
                          width: 22.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Image.asset('assets/google.png', height: 22.h),
                  label: const Text(
                    'Google ile devam et',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),

              // APPLE İLE KAYIT (Sadece iOS ise)
              if (Platform.isIOS) ...[
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton.icon(
                    onPressed: isAnyLoading
                        ? null
                        : () async {
                            setState(() => _authStatus = AuthStatus.apple);
                            try {
                              await getIt<AuthService>().signInWithApple(
                                isLogin: false,
                              );
                              if (mounted) context.push('/register-info');
                            } catch (e) {
                              if (mounted) {
                                setState(() => _authStatus = AuthStatus.none);
                                showErrorPopup(
                                  context,
                                  message:
                                      'Apple ile giriş yaparken hata oluştu. Lütfen tekrar deneyiniz.',
                                );
                              }
                            }
                          },
                    icon: _authStatus == AuthStatus.apple
                        ? SizedBox(
                            height: 22.h,
                            width: 22.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.apple, color: Colors.white, size: 24.sp),
                    label: const Text(
                      'Apple ile devam et',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
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
