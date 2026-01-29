import 'dart:io';

import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/auth_button.dart';
import 'package:outnest/components/auth_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/domain/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  // --- HATA GÖSTERME YARDIMCISI ---
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor:
            Colors.redAccent, // Hata olduğu belli olsun diye kırmızı
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleLogin() async {
    if (_isLoading) return;

    // 1. ÖNCE FORMATI TEMİZLE (Boşlukları kaldır)
    final rawNumber = _phoneController.text.replaceAll(' ', '');

    // 2. VALIDASYON KONTROLLERİ (Hata varsa durdur)
    if (rawNumber.isEmpty) {
      _showErrorSnackBar('Lütfen telefon numaranızı giriniz.');
      return;
    }

    if (!rawNumber.startsWith('5')) {
      _showErrorSnackBar('Telefon numarası 5 ile başlamalıdır.');
      return;
    }

    if (rawNumber.length != 10) {
      _showErrorSnackBar('Lütfen numaranızı eksiksiz giriniz (10 hane).');
      return;
    }

    // Her şey yolundaysa yükleniyor durumuna geç
    setState(() => _isLoading = true);

    try {
      final result = await getIt<AuthService>().sendSMS(
        phoneNumber: '+90$rawNumber',
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result.error != null) {
          // Backend'den gelen hata
          _showErrorSnackBar('Hata: ${result.error}');
        } else {
          final verificationID = result.verificationId;

          await context.push(
            '/login-verification',
            extra: {
              'verificationID': verificationID,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Beklenmedik bir hata oluştu.');
      }
      debugPrint('Beklenmedik hata: $e');
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
              size: 20.sp,
            ),
            onPressed: () => context.pop(),
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
                onSubmitted: (_) => _handleLogin(),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  // Not: Formatlayıcı boşluk eklediği için limit 10'dan fazla olmalı
                  // veya formatlayıcıdan sonra uygulanmalı.
                  // Burada kullanıcının sadece rakam girmesine izin verip
                  // formatlayıcının işini yapmasına izin veriyoruz.
                  LengthLimitingTextInputFormatter(
                    14,
                  ), // Boşluk payı ile birlikte
                  _PhoneInputFormatter(),
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
              AuthButton(
                text: 'gönder',
                onPressed: _handleLogin,
              ),

              // ... AuthButton'dan sonrası
              SizedBox(height: 24.h),

              // 1. AYRAÇ (Row burada bitmeli)
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.grey.shade300, thickness: 1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Text(
                      "veya",
                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.grey.shade300, thickness: 1),
                  ),
                ], // Row burada kapandı!
              ),

              SizedBox(height: 24.h),

              // 2. GOOGLE BUTONU (Row'un dışında, direkt Column'un içinde)
              Container(
                width: double.infinity,
                height: 48.h,
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          try {
                            await getIt<AuthService>().signInWithGoogle(
                              isLogin: true,
                            );

                            if (mounted) {
                              context.go('/home');
                            }
                          } catch (e) {
                            // Only reset loading if there was an error
                            // If successful, the navigation handles the UI transition
                            if (mounted) {
                              setState(() => _isLoading = false);
                              _showErrorSnackBar(
                                e.toString().replaceAll('Exception: ', ''),
                              );
                            }
                          }
                          // Removed 'finally' to prevent setState during/after navigation
                        },
                  icon: _isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Image.asset('assets/google.png', height: 24.h),
                  label: const Text('Google ile devam et'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),

              // Google butonundan sonra gelen kısım...
              if (Platform.isIOS) ...[
                SizedBox(height: 12.h), // Google butonuyla aradaki mesafe
                Container(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              await getIt<AuthService>().signInWithApple(
                                isLogin: true,
                              );
                              // Başarılı girişte GoRouter zaten auth state'e göre yönlendirme yapacaktır
                              if (mounted) context.go('/home');
                            } catch (e) {
                              _showErrorSnackBar(
                                e.toString().replaceAll('Exception: ', ''),
                              );
                            }
                          },
                    icon: Icon(Icons.apple, color: Colors.white, size: 24.sp),
                    label: const Text('Apple ile devam et'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
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
    // Sadece rakamları al
    final text = newValue.text.replaceAll(' ', '');
    if (text.isEmpty) return newValue;

    // Eğer 10 karakterden fazlaysa (kopyala yapıştır durumları için) kes
    final truncatedText = text.length > 10 ? text.substring(0, 10) : text;

    final buffer = StringBuffer();
    for (int i = 0; i < truncatedText.length; i++) {
      buffer.write(truncatedText[i]);
      // 5XX (boşluk) XXX (boşluk) XX (boşluk) XX
      if (i == 2 || i == 5 || i == 7) {
        if (i != truncatedText.length - 1) buffer.write(' ');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
