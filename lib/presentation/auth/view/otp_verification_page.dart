import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fpdart/fpdart.dart' show Left, Right;
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/errors/exceptions/auth_exceptions.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/presentation/auth/view/components/auth_button.dart';
import 'package:outnest/presentation/auth/view/components/otp_row.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';

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
    final logger = getIt<LoggingService>()
      ..info(
        'Doğrulama kodu gönderiliyor: $otpCode, verificationID: $_currentVerificationId',
      );

    final result = await getIt<AuthService>()
        .signInWithSms(
          verificationId: _currentVerificationId ?? '',
          smsCode: otpCode,
          isLogin: widget.isLogin,
        )
        .run();

    if (!mounted) return;
    setState(() => _isVerifying = false);

    switch (result) {
      case Right(value: final uid):
        logger.info('Kullanıcı doğrulandı: $uid');
        if (!mounted) return;
        if (widget.isLogin) {
          context.go('/splash');
        } else {
          await context.push('/register-info');
        }
      case Left(value: AuthNotFoundException(:final message)):
        if (!mounted) return;
        showErrorPopup(context, message: message);
      case Left(value: UserAlreadyExistsException(:final message)):
        if (!mounted) return;
        showErrorPopup(context, message: message);
      case Left(value: VerificationTokenException()):
        if (!mounted) return;
        showErrorPopup(
          context,
          message: 'Doğrulama başarısız. Lütfen tekrar deneyiniz.',
        );
      case Left(value: final _):
        if (!mounted) return;
        showErrorPopup(
          context,
          message: 'Giriş yapılırken bir hata oluştu. Lütfen tekrar deneyiniz.',
        );
    }
  }

  Future<void> _handleResend() async {
    if (_countdown > 0 || _isResending) return;

    setState(() => _isResending = true);

    final result = await getIt<AuthService>()
        .resendSMS(
          phoneNumber: widget.phoneNumber ?? '',
          resendToken: _currentResendToken,
        )
        .run();

    if (!mounted) return;
    setState(() => _isResending = false);

    switch (result) {
      case Right(value: final sms):
        setState(() {
          _currentVerificationId = sms.verificationId;
          _currentResendToken = sms.resendToken;
        });
        _startTimer();
        showInfoPopup(context, message: 'Yeni kod gönderildi!');
      case Left(value: SMSTimeoutException()):
        showErrorPopup(
          context,
          message: 'Zaman aşımı. Lütfen tekrar deneyiniz.',
        );
      case Left(value: final _):
        showErrorPopup(
          context,
          message: 'Kod gönderilemedi. Lütfen tekrar deneyiniz.',
        );
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
              Symbols.reply,
              weight: 400,
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
