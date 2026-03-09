import 'dart:io';

import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/presentation/auth/view/components/auth_button.dart';
import 'package:outnest/presentation/auth/view/components/auth_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/presentation/shared/form/formatters/phone_input_formatter.dart';

// Yükleme durumlarını ayırt etmek için enum
enum AuthStatus { none, phone, google, apple }

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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleLogin() async {
    // Herhangi bir işlem sürüyorsa engelle
    if (_authStatus != AuthStatus.none) return;

    final rawNumber = _phoneController.text.replaceAll(' ', '');

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

    setState(() => _authStatus = AuthStatus.phone);

    try {
      final result = await getIt<AuthService>().sendSMS(
        phoneNumber: '+90$rawNumber',
      );

      if (mounted) {
        setState(() => _authStatus = AuthStatus.none);

        if (result.error != null) {
          _showErrorSnackBar('Hata: ${result.error}');
        } else {
          final verificationID = result.verificationId;
          final resendToken = result.resendToken;
          await context.push(
            '/login-verification',
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
        _showErrorSnackBar('Beklenmedik bir hata oluştu.');
      }
      debugPrint('Beklenmedik hata: $e');
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
              Icons.arrow_back_ios_new,
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
                              isLogin: true,
                            );

                            if (mounted) {
                              context.go('/home');
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => _authStatus = AuthStatus.none);
                              _showErrorSnackBar(
                                e.toString().replaceAll('Exception: ', ''),
                              );
                            }
                          }
                        },
                  // Sadece Google işlemi yapılıyorsa spinner göster
                  icon: _authStatus == AuthStatus.google
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

              if (Platform.isIOS) ...[
                SizedBox(height: 12.h),
                // APPLE BUTONU
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
                                isLogin: true,
                              );
                              if (mounted) context.go('/home');
                            } catch (e) {
                              if (mounted) {
                                setState(() => _authStatus = AuthStatus.none);
                                _showErrorSnackBar(
                                  e.toString().replaceAll('Exception: ', ''),
                                );
                              }
                            }
                          },
                    // Sadece Apple işlemi yapılıyorsa spinner (veya siyah üzerine beyaz loading) göster
                    icon: _authStatus == AuthStatus.apple
                        ? SizedBox(
                            height: 20.h,
                            width: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.apple, color: Colors.white, size: 24.sp),
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
