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

  bool _isLoading = false; // Sayfada bir yükleniyor durumu tut

  void _handleLogin() async {
    if (_isLoading) return; // Çift tıklamayı engelle

    setState(() => _isLoading = true);

    try {
      final rawNumber = _phoneController.text.replaceAll(' ', '');
      final result = await getIt<AuthService>().sendSMS(
        phoneNumber: '+90$rawNumber',
      );

      // Widget hala yerindeyse işlemleri yap
      if (mounted) {
        setState(() => _isLoading = false); // Yüklemeyi bitir

        if (result.error != null) {
          // Hata varsa kullanıcıya göster (hala sayfada olduğu için güvenli)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: ${result.error}')),
          );
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
      if (mounted) setState(() => _isLoading = false);
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
                  LengthLimitingTextInputFormatter(10),
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
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 2 || i == 5 || i == 7) {
        if (i != text.length - 1) buffer.write(' ');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
