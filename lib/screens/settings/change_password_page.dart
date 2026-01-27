import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isOldPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 24.h),

            // Eski Şifre
            _buildPasswordField(
              controller: _oldPasswordController,
              hintText: 'eski şifre',
              isObscured: _isOldPasswordObscured,
              onVisibilityChanged: () {
                setState(() {
                  _isOldPasswordObscured = !_isOldPasswordObscured;
                });
              },
            ),

            SizedBox(height: 24.h),

            // Yeni Şifre
            _buildPasswordField(
              controller: _newPasswordController,
              hintText: 'yeni şifre',
              isObscured: _isNewPasswordObscured,
              onVisibilityChanged: () {
                setState(() {
                  _isNewPasswordObscured = !_isNewPasswordObscured;
                });
              },
            ),

            SizedBox(height: 24.h),

            // Yeni Şifre Tekrar
            _buildPasswordField(
              controller: _confirmPasswordController,
              hintText: 'yeni şifre tekrar',
              isObscured: _isConfirmPasswordObscured,
              isLast: true,
              onVisibilityChanged: () {
                setState(() {
                  _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                });
              },
            ),

            SizedBox(height: 142.h),

            // Kaydet Butonu
            _buildButton(
              text: 'kaydet',
              onPressed: () {
                debugPrint('Eski: ${_oldPasswordController.text}');
                debugPrint('Yeni: ${_newPasswordController.text}');

                // Basit kontrol
                if (_newPasswordController.text.isNotEmpty &&
                    _newPasswordController.text ==
                        _confirmPasswordController.text) {
                  // İşlem başarılı, geri dön
                  Navigator.pop(context);
                } else {
                  debugPrint('Hata: Şifreler uyuşmuyor veya boş.');
                }
              },
            ),
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
          size: 24.sp,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Şifre Değiştir',
        style: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.onBackgroundColor,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool isObscured,
    required VoidCallback onVisibilityChanged,
    bool isLast = false,
  }) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      obscureText: isObscured,
      cursorColor: AppColors.tertiaryColor,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.onBackgroundColor,
      ),
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      decoration: InputDecoration(
        hintText: hintText,
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

        // GÖZ İKONU
        suffixIcon: Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: IconButton(
            icon: Icon(
              isObscured
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textGrey,
              size: 20.sp,
            ),
            onPressed: onVisibilityChanged,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40.r),
          borderSide: const BorderSide(
            color: AppColors.tertiaryColor,
            width: 1.5,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 173.w,
      height: 40.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F4668),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
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
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
