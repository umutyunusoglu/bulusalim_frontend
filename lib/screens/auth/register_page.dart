import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/auth_button.dart';
import 'package:outnest/components/auth_input.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/services/auth_service.dart';
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

  bool _isLoading = false;

  // --- HATA GÖSTERME YARDIMCISI ---
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

  void _handleSendCode() async {
    if (_isLoading) return;

    // 1. FORMATI TEMİZLE
    final rawNumber = _phoneController.text.replaceAll(' ', '');

    // 2. VALIDASYON KONTROLLERİ
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

    // Her şey yolundaysa işlemi başlat
    setState(() => _isLoading = true);

    try {
      final result = await getIt<AuthService>().sendSMS(
        phoneNumber: '+90$rawNumber',
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result.error != null) {
          _showErrorSnackBar('Hata: ${result.error}');
        } else {
          final verificationID = result.verificationId;

          await context.push(
            '/verification-code-field',
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
                  // DİKKAT: Boşluklar dahil 14 karaktere izin veriyoruz
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
    // 1. Önce sadece rakamları al
    final text = newValue.text.replaceAll(' ', '');

    if (text.isEmpty) return newValue;

    // 2. Eğer 10 karakterden uzunsa kes (güvenlik)
    final truncatedText = text.length > 10 ? text.substring(0, 10) : text;

    final buffer = StringBuffer();
    for (int i = 0; i < truncatedText.length; i++) {
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
