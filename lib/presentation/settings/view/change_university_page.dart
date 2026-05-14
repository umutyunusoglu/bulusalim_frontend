import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/datasources/university_datasource.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';
import 'package:outnest/presentation/shared/form/sanitizer.dart';
import 'package:outnest/presentation/shared/form/validators/validate_university_mail.dart';
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
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isCodeSent = false;
  String? _detectedUniversity;
  List<UniversitySuggestion> _emailSuggestions = const [];
  bool _hasCheckedEmail = false;

  @override
  void dispose() {
    _emailController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onEmailChanged(String email) async {
    if (_isCodeSent) {
      setState(() {
        _isCodeSent = false;
        _pinController.clear();
      });
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _detectedUniversity = null;
        _emailSuggestions = const [];
        _hasCheckedEmail = false;
      });
      return;
    }

    try {
      final ds = getIt<UniversityDatasource>();
      final uniNames = await ds.getUniversityOfMail(email.trim(), 'Turkey');

      if (uniNames.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _detectedUniversity = uniNames.first;
          _emailSuggestions = const [];
          _hasCheckedEmail = true;
        });
      } else {
        final suggestions = await ds.findSuggestionsForMail(
          email.trim(),
          'Turkey',
        );
        if (!mounted) return;
        setState(() {
          _detectedUniversity = null;
          _emailSuggestions = suggestions;
          _hasCheckedEmail = true;
        });

        // Suggestion varsa klavyeyi kapat ki banner görünsün
        if (suggestions.isNotEmpty) {
          FocusScope.of(context).unfocus();
        }
      }
    } catch (e) {
      debugPrint('Uni Check Error: $e');
    }
  }

  void _applySuggestion(UniversitySuggestion s) {
    _emailController.text = s.suggestedEmail;
    _emailController.selection = TextSelection.fromPosition(
      TextPosition(offset: s.suggestedEmail.length),
    );
    setState(() {
      _detectedUniversity = s.universityName;
      _emailSuggestions = const [];
    });
  }

  void _showSuggestionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bunlardan birini mi demek istediniz?',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackgroundColor,
                ),
              ),
              SizedBox(height: 16.h),
              ..._emailSuggestions.map(
                (s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    s.suggestedEmail,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tertiaryColor,
                    ),
                  ),
                  subtitle: Text(
                    s.universityName,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12.sp,
                      color: AppColors.textGrey,
                    ),
                  ),
                  trailing: Icon(
                    Symbols.arrow_forward,
                    size: 18.sp,
                    color: AppColors.tertiaryColor,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _applySuggestion(s);
                  },
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSendCode() async {
    if (_detectedUniversity == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await getIt<UserRepository>().sendVerificationEmail(
        sanitizeEmail(_emailController.text),
      );
      setState(() => _isCodeSent = true);
      _pinFocusNode.requestFocus();

      if (mounted) {
        showInfoPopup(context, message: 'Doğrulama kodu gönderildi!');
      }
    } catch (e) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOTP() async {
    if (_pinController.text.length < 6) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await getIt<UserRepository>().verifyEmail(
        sanitizeEmail(_emailController.text),
        _detectedUniversity!,
        _pinController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, _detectedUniversity);
      }
    } catch (e) {
      _pinController.clear();
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: 32.h),
              _buildEmailField(),

              // Dinamik Durum Bilgisi
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: _buildStatusMessage(),
              ),

              // Suggestion banner
              if (_detectedUniversity == null &&
                  _emailSuggestions.isNotEmpty) ...[
                SizedBox(height: 12.h),
                if (_emailSuggestions.length == 1)
                  _buildSuggestionBanner(_emailSuggestions.first)
                else
                  _buildMultiSuggestionBanner(),
              ],

              SizedBox(height: 16.h),
              Text(
                _hasCheckedEmail &&
                        _detectedUniversity == null &&
                        _emailSuggestions.isEmpty
                    ? 'Bu üniversite henüz desteklenmiyor. Lütfen başka bir mail deneyin veya bize bildirin.'
                    : 'Üniversiteni doğruladığında, üniversite bilgin profilinde otomatik olarak görünür.',
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
                onPressed: (_isLoading || !_isCodeSent)
                    ? null
                    : _handleVerifyOTP,
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionBanner(UniversitySuggestion suggestion) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () => _applySuggestion(suggestion),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.tertiaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.tertiaryColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Symbols.lightbulb,
              size: 18.sp,
              color: AppColors.tertiaryColor,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bunu mu demek istediniz?',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textGrey,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    suggestion.suggestedEmail,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tertiaryColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    suggestion.universityName,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 11.sp,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Symbols.arrow_forward,
              size: 18.sp,
              color: AppColors.tertiaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSuggestionBanner() {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: _showSuggestionsSheet,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.tertiaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.tertiaryColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Symbols.lightbulb,
              size: 18.sp,
              color: AppColors.tertiaryColor,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                '${_emailSuggestions.length} olası üniversite bulundu. Hangisini demek istediniz?',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onBackgroundColor,
                ),
              ),
            ),
            Icon(
              Symbols.arrow_forward,
              size: 18.sp,
              color: AppColors.tertiaryColor,
            ),
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
    return TextFormField(
      controller: _emailController,
      onChanged: _onEmailChanged,
      validator: (value) => validateUniversityMail(value, _detectedUniversity),
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
        final Uri url = Uri.parse('https://forms.gle/AJXYJXhBPQaeka6u9');
        launchUrl(url, mode: LaunchMode.inAppWebView);
      },
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textGrey,
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
