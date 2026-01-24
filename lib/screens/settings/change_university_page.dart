import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';

class ChangeUniversityPage extends StatefulWidget {
  const ChangeUniversityPage({super.key});

  @override
  State<ChangeUniversityPage> createState() => _ChangeUniversityPageState();
}

class _ChangeUniversityPageState extends State<ChangeUniversityPage> {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50.w,
      height: 50.h,
      textStyle: TextStyle(
        fontSize: 20.sp,
        color: AppColors.onBackgroundColor,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputFillColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(
        color: AppColors.tertiaryColor,
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(8.r),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: const Color(
          0xFFEDF2F7,
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
            _buildEmailField(),

            SizedBox(height: 16.h),
            Text(
              'Üniversiteni doğruladığında, üniversite bilgin profilinde otomatik olarak görünür. Bu sayede diğer kullanıcılar için daha güvenilir bir profil oluşturur ve üniversitelere özel özelliklere erişebilirsin.',
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
              'Doğrulama kodu bu maile gönderilecektir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textGrey,
              ),
            ),

            SizedBox(height: 24.h),
            _buildButton(
              text: 'gönder',
              onPressed: () {
                debugPrint('Kod gönderiliyor: ${_emailController.text}');
                _pinFocusNode.requestFocus();
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

            Pinput(
              length: 6,
              controller: _pinController,
              focusNode: _pinFocusNode,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              submittedPinTheme: submittedPinTheme,
              cursor: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    width: 22,
                    height: 1,
                    color: AppColors.tertiaryColor,
                  ),
                ],
              ),
              onCompleted: (pin) {
                debugPrint('Girilen tam kod: $pin');
              },
            ),

            SizedBox(height: 24.h),
            _buildButton(
              text: 'onayla',
              onPressed: () {
                String code = _pinController.text;
                if (code.length == 6) {
                  debugPrint('Onaylanan Kod: $code');
                  Navigator.pop(context, 'Yeni Üniversite İsmi');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen 6 haneli kodu giriniz.'),
                    ),
                  );
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
        icon: const Icon(Icons.arrow_back, color: AppColors.iconColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Üniversiteni Doğrula',
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

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      textAlign: TextAlign.center,
      cursorColor: AppColors.tertiaryColor,
      style: TextStyle(
        fontSize: 14.sp,
        color: AppColors.onBackgroundColor,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: '@edu.tr',
        hintStyle: TextStyle(
          color: AppColors.textGrey.withOpacity(0.7),
          fontSize: 14.sp,
        ),
        filled: true,
        fillColor: const Color(0xFFF2F4F7),
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.r),
          borderSide: BorderSide.none,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: 180.w,
      height: 48.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F4668),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
