import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';

class ChangePhoneNumberPage extends StatefulWidget {
  const ChangePhoneNumberPage({super.key});

  @override
  State<ChangePhoneNumberPage> createState() => _ChangePhoneNumberPageState();
}

class _ChangePhoneNumberPageState extends State<ChangePhoneNumberPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  final AuthService _authService = getIt<AuthService>();
  final UserRepository _userRepository = getIt<UserRepository>();

  String? _verificationId;
  int? _resendToken;
  @override
  void initState() {
    super.initState();
    // Başlangıçta +90 ekle
    _phoneController.text = '+90 ';
    _phoneController.selection = TextSelection.fromPosition(
      TextPosition(offset: _phoneController.text.length),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48.w,
      height: 56.h,
      textStyle: TextStyle(
        fontSize: 20.sp,
        color: AppColors.onBackgroundColor,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputFillColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.dividerColor,
          width: 1,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(
        color: AppColors.tertiaryColor,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(8.r),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.lightCloud,
        border: Border.all(
          color: AppColors.secondaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 32.h),

            _buildPhoneField(),

            SizedBox(height: 16.h),
            Text(
              'Telefon numaran, hesabının güvenliğini sağlamak ve gerektiğinde seninle iletişime geçebilmek için kullanılır. Dilediğin zaman değiştirebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Doğrulama kodu bu numaraya gönderilecektir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textGrey,
              ),
            ),

            SizedBox(height: 24.h),

            // Gönder Butonu
            _buildButton(
              text: 'gönder',
              onPressed: () async {
                String fullPhone = _phoneController.text.replaceAll(
                  ' ',
                  '',
                ); // +905XXXXXXXXX

                // AuthService üzerinden SMS gönder
                final result = await _authService.sendSMS(
                  phoneNumber: fullPhone,
                );

                if (result.error != null) {
                  // Hata göster (SnackBar)
                } else {
                  setState(() {
                    _verificationId = result.verificationId;
                    _resendToken = result.resendToken;
                  });
                  // OTP alanına odaklan
                  _pinFocusNode.requestFocus();
                }
              },
            ),

            SizedBox(height: 60.h),
            Text(
              'Doğrulama Kodu',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.onBackgroundColor,
              ),
            ),
            SizedBox(height: 20.h),

            // --- PINPUT (OTP) ---
            Pinput(
              length: 6,
              controller: _pinController,
              focusNode: _pinFocusNode,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              submittedPinTheme: submittedPinTheme,
              pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
              showCursor: true,
              keyboardType: TextInputType.number,
              cursor: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 9.h),
                    width: 22.w,
                    height: 1.5.h,
                    color: AppColors.tertiaryColor,
                  ),
                ],
              ),
              onCompleted: (pin) {
                debugPrint('Girilen tam kod: $pin');
              },
            ),
            SizedBox(height: 24.h),

            // Onayla Butonu
            _buildButton(
              text: 'onayla',
              onPressed: () async {
                if (_verificationId == null) return;

                String code = _pinController.text;
                try {
                  // Yeni eklediğimiz metodu çağırıyoruz
                  await _authService.verifyAndChangePhoneNumber(
                    verificationId: _verificationId!,
                    smsCode: code,
                  );

                  // İşlem başarılıysa Firestore'u güncelle ve geri dön
                  await _userRepository.updateUser(
                    _authService.getCurrentUserID(),
                    {
                      'phoneNumber': _phoneController.text,
                    },
                  );

                  Navigator.pop(context, true);
                } catch (e) {
                  // Hata mesajı göster
                }
              },
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.iconColor,
          size: 20.sp,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Telefon Numarası',
        style: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.onBackgroundColor,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildPhoneField() {
    return TextField(
      controller: _phoneController,
      textAlign: TextAlign.center,
      cursorColor: AppColors.tertiaryColor,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        _PhoneNumberFormatter(),
      ],
      style: TextStyle(
        fontSize: 14.sp,
        color: AppColors.onBackgroundColor,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: '+90 5XX XXX XX XX',
        hintStyle: TextStyle(
          color: AppColors.textGrey.withOpacity(0.6),
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: AppColors.inputFillColor,
        contentPadding: EdgeInsets.symmetric(
          vertical: 16.h,
          horizontal: 24.w,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.r),
          borderSide: const BorderSide(
            color: AppColors.dividerColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.r),
          borderSide: const BorderSide(
            color: AppColors.tertiaryColor,
            width: 2,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.r),
          borderSide: const BorderSide(
            color: AppColors.dividerColor,
            width: 1,
          ),
        ),
      ),
      onTap: () {
        // Tıklandığında imleci +90 sonrasına taşı
        if (_phoneController.text == '+90 ') {
          _phoneController.selection = TextSelection.fromPosition(
            TextPosition(offset: _phoneController.text.length),
          );
        }
      },
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 180.w,
      height: 48.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tertiaryColor,
          foregroundColor: AppColors.onPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.onPrimaryColor,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // +90 prefix'i her zaman kalsın
    if (!newValue.text.startsWith('+90 ')) {
      return oldValue;
    }

    // +90 sonrası sadece rakamları al
    String digitsOnly = newValue.text
        .replaceAll('+90 ', '')
        .replaceAll(RegExp(r'\D'), '');

    // Maksimum 10 rakam (5XX XXX XX XX)
    if (digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(0, 10);
    }

    // Formatlama: +90 5XX XXX XX XX
    String formatted = '+90 ';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 3 || i == 6 || i == 8) {
        formatted += ' ';
      }
      formatted += digitsOnly[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
