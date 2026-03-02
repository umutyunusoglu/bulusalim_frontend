import 'dart:async';

import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/presentation/auth/view/components/auth_button.dart';
import 'package:outnest/presentation/auth/view/components/otp_row.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({
    this.verificationID,
    this.phoneNumber,
    this.resendToken, // <-- EKLENDİ
    super.key,
    this.isLogin = false,
  });

  final bool isLogin;
  final String? phoneNumber;
  final String? verificationID;
  final int? resendToken; // <-- EKLENDİ

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  // --- EKLENEN STATE DEĞİŞKENLERİ ---
  String? _currentVerificationId;
  int? _currentResendToken;

  bool _isResending = false;
  bool _isVerifying = false;
  int _countdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationID;
    _currentResendToken = widget.resendToken;
    _startTimer();
  }

  void _startTimer() {
    setState(() => _countdown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Memory leak olmaması için Timer'ı iptal et
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_isVerifying) return;
    final otpCode = _controllers.map((e) => e.text).join();
    if (otpCode.length != 6) return;

    setState(() => _isVerifying = true);
    try {
      final logger = getIt<LoggingService>()
        ..info(
          'Doğrulama kodu gönderiliyor: $otpCode, verificationID: $_currentVerificationId',
        );

      // widget.verificationID YERİNE _currentVerificationId KULLANILIYOR
      final result = await getIt<AuthService>().signInWithSms(
        verificationId: _currentVerificationId ?? '',
        smsCode: otpCode,
        isLogin: widget.isLogin,
      );

      logger.info('Kullanıcı doğrulandı: $result');

      if (!mounted) return;

      if (widget.isLogin) {
        context.go('/home');
      } else {
        await context.push('/register-info');
      }
    } catch (e) {
      debugPrint('Hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Doğrulama hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // --- YENİ EKLENEN RESEND METODU ---
  Future<void> _handleResend() async {
    if (_countdown > 0 || _isResending) return; // Süre bitmediyse işlem yapma

    setState(() => _isResending = true);

    try {
      final result = await getIt<AuthService>().resendSMS(
        phoneNumber: widget.phoneNumber ?? '',
        resendToken: _currentResendToken,
      );

      if (result.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kod gönderilemedi: ${result.error}')),
          );
        }
      } else {
        // Yeni doğrulama verilerini kaydet ve timer'ı baştan başlat
        setState(() {
          _currentVerificationId = result.verificationId;
          _currentResendToken = result.resendToken;
        });
        _startTimer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yeni kod gönderildi!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Resend Hatası: $e');
    } finally {
      if (mounted) setState(() => _isResending = false);
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
                text: _isVerifying
                    ? 'lütfen bekleyin...'
                    : (widget.isLogin ? 'giriş yap' : 'gönder'),
                onPressed: _isVerifying ? null : _handleVerify,
              ),
              SizedBox(height: 12.h),
              Center(
                child: GestureDetector(
                  onTap: _countdown == 0 && !_isResending
                      ? _handleResend
                      : null,
                  // HitTestBehavior.opaque: Padding ile verdiğimiz şeffaf alanın da tıklanabilir olmasını sağlar.
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    // Tıklanabilir alanı (hitbox) dikey ve yatayda genişletiyoruz
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 20.w,
                    ),
                    child: Text(
                      _isResending
                          ? 'gönderiliyor...'
                          : _countdown > 0
                          ? 'kodu tekrar gönder ($_countdown s)'
                          : 'kodu tekrar gönder',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',

                        fontSize: 14.sp, // 10.sp'den 14.sp'ye büyütüldü
                        fontWeight: FontWeight
                            .w600, // w400'den w600'e çekilerek daha belirgin yapıldı
                        color: _countdown > 0
                            ? Colors.grey
                            : AppColors.tertiaryColor,
                        decoration: _countdown > 0
                            ? null
                            : TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }
}
