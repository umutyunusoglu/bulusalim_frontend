import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fpdart/fpdart.dart' show Left, Right;
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/errors/exceptions/auth_exceptions.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/presentation/auth/view/components/auth_button.dart';
import 'package:outnest/presentation/auth/view/components/otp_row.dart';
import 'package:outnest/presentation/auth/view/components/register_fallback_sheet.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';

class OtpVerificationPage extends HookWidget {
  const OtpVerificationPage({
    this.verificationID,
    this.phoneNumber,
    this.resendToken,
    super.key,
    this.isLogin = false,
  });

  final bool isLogin;
  final String? phoneNumber;
  final String? verificationID;
  final int? resendToken;

  @override
  Widget build(BuildContext context) {
    final controllers = List.generate(6, (_) => useTextEditingController());

    final currentVerificationId = useState<String?>(verificationID);
    final currentResendToken = useState<int?>(resendToken);
    final isResending = useState(false);
    final isVerifying = useState(false);

    final countdown = useValueNotifier(30);
    final timerRef = useRef<Timer?>(null);

    final errorCount = useRef(0);
    final showFallback = useState(false);

    void startTimer({bool afterResend = false}) {
      countdown.value = 30;
      timerRef.value?.cancel();
      timerRef.value = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (countdown.value > 0) {
          countdown.value--;
        } else {
          timer.cancel();
          if (afterResend && !isLogin) showFallback.value = true;
        }
      });
    }

    useEffect(() {
      startTimer();
      return () => timerRef.value?.cancel();
    }, const []);

    useEffect(() {
      if (!showFallback.value) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showRegisterFallbackSheet(context).then((_) {
          if (context.mounted) showFallback.value = false;
        });
      });
      return null;
    }, [showFallback.value]);

    void triggerFallbackIfNeeded(VoidCallback showError) {
      if (isLogin) {
        showError();
        return;
      }
      errorCount.value++;
      if (errorCount.value >= 2) {
        showFallback.value = true;
      } else {
        showError();
      }
    }

    Future<void> handleVerify() async {
      if (isVerifying.value) return;
      final otpCode = controllers.map((e) => e.text).join();
      if (otpCode.length != 6) return;

      isVerifying.value = true;

      final logger = getIt<LoggingService>()
        ..info(
          'Doğrulama kodu gönderiliyor: $otpCode, '
          'verificationID: ${currentVerificationId.value}',
        );

      final result = await getIt<AuthService>()
          .signInWithSms(
            verificationId: currentVerificationId.value ?? '',
            smsCode: otpCode,
            isLogin: isLogin,
          )
          .run();

      if (!context.mounted) return;
      isVerifying.value = false;

      switch (result) {
        case Right(value: final uid):
          logger.info('Kullanıcı doğrulandı: $uid');
          if (!context.mounted) return;
          if (isLogin) {
            context.go('/splash');
          } else {
            await context.push('/register-info');
          }
        case Left(value: AuthNotFoundException(:final message)):
          if (!context.mounted) return;
          triggerFallbackIfNeeded(
            () => showErrorPopup(context, message: message),
          );

        case Left(value: VerificationTokenException()):
          if (!context.mounted) return;
          triggerFallbackIfNeeded(
            () => showErrorPopup(
              context,
              message: 'Doğrulama başarısız. Lütfen tekrar deneyiniz.',
            ),
          );

        case Left(value: final _):
          if (!context.mounted) return;
          triggerFallbackIfNeeded(
            () => showErrorPopup(
              context,
              message:
                  'Giriş yapılırken bir hata oluştu. Lütfen tekrar deneyiniz.',
            ),
          );
      }
    }

    Future<void> handleResend() async {
      if (countdown.value > 0 || isResending.value) return;

      isResending.value = true;

      final result = await getIt<AuthService>()
          .resendSMS(
            phoneNumber: phoneNumber ?? '',
            resendToken: currentResendToken.value,
          )
          .run();

      if (!context.mounted) return;
      isResending.value = false;

      switch (result) {
        case Right(value: final sms):
          currentVerificationId.value = sms.verificationId;
          currentResendToken.value = sms.resendToken;
          startTimer(afterResend: true);
          showInfoPopup(context, message: 'Yeni kod gönderildi!');
        case Left(value: SMSTimeoutException()):
          if (!isLogin) showFallback.value = true;

        case Left(value: final _):
          showErrorPopup(
            context,
            message: 'Kod gönderilemedi. Lütfen tekrar deneyiniz.',
          );
      }
    }

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
              if (isLogin) {
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
                child: OtpRow(controllers: controllers),
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
                text: isVerifying.value
                    ? 'lütfen bekleyin...'
                    : (isLogin ? 'giriş yap' : 'gönder'),
                onPressed: isVerifying.value ? null : handleVerify,
              ),
              SizedBox(height: 12.h),
              Center(
                child: ValueListenableBuilder<int>(
                  valueListenable: countdown,
                  builder: (context, count, _) {
                    return GestureDetector(
                      onTap: count == 0 && !isResending.value
                          ? handleResend
                          : null,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 12.h,
                          horizontal: 20.w,
                        ),
                        child: Text(
                          isResending.value
                              ? 'gönderiliyor...'
                              : count > 0
                              ? 'kodu tekrar gönder ($count s)'
                              : 'kodu tekrar gönder',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: count > 0
                                ? Colors.grey
                                : AppColors.tertiaryColor,
                            decoration: count > 0
                                ? null
                                : TextDecoration.underline,
                          ),
                        ),
                      ),
                    );
                  },
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
