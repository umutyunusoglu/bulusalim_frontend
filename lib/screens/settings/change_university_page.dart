import 'dart:async';

import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/datasources/university_datasource.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';
import 'package:url_launcher/url_launcher.dart';

class ChangeUniversityPage extends StatefulWidget {
  const ChangeUniversityPage({super.key});

  @override
  State<ChangeUniversityPage> createState() => _ChangeUniversityPageState();
}

class _ChangeUniversityPageState extends State<ChangeUniversityPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isCodeSent = false;
  String? _detectedUniversity;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onEmailChanged(String email) async {
    // E-posta her değiştiğinde süreci resetliyoruz ki bug oluşmasın
    if (_isCodeSent) {
      setState(() {
        _isCodeSent = false;
        _pinController.clear();
      });
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _detectedUniversity = null;
        _errorMessage = null;
      });
      return;
    }

    try {
      final uniNames = await getIt<UniversityDatasource>().getUniversityOfMail(
        email.trim(),
        'Turkey',
      );

      setState(() {
        if (uniNames.isNotEmpty) {
          _detectedUniversity = uniNames.first;
          _errorMessage = null;
        } else {
          _detectedUniversity = null;
          _errorMessage = 'Üniversite e-postası tanınamadı.';
        }
      });
    } catch (e) {
      debugPrint('Uni Check Error: $e');
    }
  }

  Future<void> _handleSendCode() async {
    if (_detectedUniversity == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await getIt<UserRepository>().sendVerificationEmail(
        _emailController.text.trim(),
      );
      setState(() => _isCodeSent = true);
      _pinFocusNode.requestFocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doğrulama kodu gönderildi!')),
        );
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOTP() async {
    if (_pinController.text.length < 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await getIt<UserRepository>().verifyEmail(
        _emailController.text.trim(),
        _detectedUniversity!,
        _pinController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, _detectedUniversity);
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
      _pinController.clear(); // Hatalı kod girilirse temizle
    } finally {
      setState(() => _isLoading = false);
    }
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
      border: Border.all(color: AppColors.tertiaryColor, width: 1.5),
      borderRadius: BorderRadius.circular(8.r),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: const Color(0xFFEDF2F7),
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

            // Dinamik Durum Bilgisi
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: _buildStatusMessage(),
            ),

            SizedBox(height: 16.h),
            Text(
              'Üniversiteni doğruladığında, üniversite bilgin profilinde otomatik olarak görünür.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),

            SizedBox(height: 24.h),
            _buildButton(
              text: 'gönder',
              // Kod gönderildiyse butonu pasif yapıyoruz (tekrar basılmasın)
              onPressed:
                  (_isLoading || _detectedUniversity == null || _isCodeSent)
                  ? null
                  : _handleSendCode,
            ),

            SizedBox(height: 8.h),
            _buildReportButton(),

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
              enabled: _isCodeSent,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              submittedPinTheme: submittedPinTheme,
              onCompleted: (_) => _handleVerifyOTP(),
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
            ),

            SizedBox(height: 24.h),
            _buildButton(
              text: 'onayla',
              onPressed: (_isLoading || !_isCodeSent) ? null : _handleVerifyOTP,
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    if (_detectedUniversity != null && !_isCodeSent) {
      return Text(
        'Tespit Edildi: $_detectedUniversity',
        style: TextStyle(
          color: Colors.green,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (_isCodeSent) {
      return Text(
        'Kod şuraya gönderildi: ${_emailController.text}',
        style: TextStyle(
          color: AppColors.tertiaryColor,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: TextStyle(color: Colors.red, fontSize: 12.sp),
      );
    }
    return const SizedBox.shrink();
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
      onChanged: _onEmailChanged,
      textAlign: TextAlign.center,
      cursorColor: AppColors.tertiaryColor,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(
        fontSize: 14.sp,
        color: AppColors.onBackgroundColor,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'email@universite.edu.tr',
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
          borderSide: BorderSide(
            color: AppColors.tertiaryColor.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 180.w,
      height: 48.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F4668),
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.h,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
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

  Widget _buildReportButton() {
    return TextButton(
      onPressed: () async {
        final url = Uri.parse('https://forms.gle/AJXYJXhBPQaeka6u9');

        unawaited(launchUrl(url, mode: LaunchMode.inAppWebView));
      },
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textGrey, // Temanızdaki gri renk
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      ),
      child: Text(
        'Üniversitenizi bulamıyor musunuz? Bize bildirin.',
        style: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 12.sp,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
