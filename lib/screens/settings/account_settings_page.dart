import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/screens/settings/change_account_type_page.dart';
import 'package:bulusalim/screens/settings/change_password_page.dart';
import 'package:bulusalim/screens/settings/change_phone_number.dart'; // Dosya ismine dikkat
import 'package:bulusalim/screens/settings/change_university_page.dart';
import 'package:bulusalim/screens/settings/connect_social_media_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  String _university = 'İstanbul Teknik Üniversitesi';
  String _phoneNumber = '+90 123 456 78 90';
  String _socialMedia = 'instagram.com/elif_dogan';
  String _accountType = 'Kişisel Hesap';
  bool _isPrivateAccount = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUniversitySection(),
            SizedBox(height: 28.h),
            _buildPhoneSection(),
            SizedBox(height: 28.h),
            _buildSocialMediaSection(),
            SizedBox(height: 28.h),
            _buildDivider(),
            SizedBox(height: 24.h),
            _buildPrivacySection(),
            SizedBox(height: 24.h),
            _buildDivider(),
            SizedBox(height: 24.h),
            _buildAccountTypeSection(),
            SizedBox(height: 28.h),
            _buildPasswordSection(),
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
        'Hesap Ayarları',
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

  // --- 1. ÜNİVERSİTE YÖNLENDİRMESİ ---
  Widget _buildUniversitySection() {
    return _buildSettingItem(
      label: 'Üniversite',
      value: _university,
      trailing: _buildChangeButton(() async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChangeUniversityPage(),
          ),
        );

        if (result != null && result is String) {
          setState(() {
            _university = result;
          });
        }
      }),
    );
  }

  // --- 2. TELEFON YÖNLENDİRMESİ ---
  Widget _buildPhoneSection() {
    return _buildSettingItem(
      label: 'Telefon\nNumarası',
      value: _phoneNumber,
      showArrow: true,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChangePhoneNumberPage(),
          ),
        );

        if (result != null && result is String) {
          setState(() {
            _phoneNumber = result;
          });
        }
      },
    );
  }

  // --- 3. SOSYAL MEDYA YÖNLENDİRMESİ ---
  Widget _buildSocialMediaSection() {
    return _buildSettingItem(
      label: 'Sosyal\nMedya',
      value: _socialMedia,
      showArrow: true,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ConnectSocialMediaPage(),
          ),
        );

        // Eğer sosyal medya sayfasından bir seçim dönerse güncelle
        if (result != null && result is String) {
          setState(() {
            _socialMedia = result;
          });
        }
      },
    );
  }

  Widget _buildPrivacySection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hesap Gizliliği',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onBackgroundColor,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Hesabın açıkken profilin ve paylaşımların herkes tarafından görülebilir. Hesabını gizlediğinde ise paylaşımlarını yalnızca onayladığın kişiler görür. Profil fotoğrafın ve kullanıcı adı gibi bazı bilgiler her durumda herkese açıktır.',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        _buildPrivacySwitch(),
      ],
    );
  }

  // --- 4. HESAP TÜRÜ YÖNLENDİRMESİ  ---
  Widget _buildAccountTypeSection() {
    return _buildSettingItem(
      label: 'Hesap Türü',
      value: _accountType,
      showArrow: true,
      valueColor: AppColors.textGrey,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeAccountTypePage(
              currentType: _accountType,
            ),
          ),
        );

        if (result != null && result is String) {
          setState(() {
            _accountType = result;
          });
        }
      },
    );
  }

  Widget _buildPasswordSection() {
    return Row(
      children: [
        SizedBox(
          width: 110.w,
          child: Text(
            'Şifre Değiştir',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.onBackgroundColor,
              height: 1.3,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChangePasswordPage(),
              ),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.iconColor,
              size: 24.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: AppColors.dividerColor,
      thickness: 1,
      height: 1,
    );
  }

  Widget _buildPrivacySwitch() {
    return Transform.scale(
      scale: 0.8,
      child: Switch.adaptive(
        value: _isPrivateAccount,
        activeColor: Colors.white,
        activeTrackColor: AppColors.primaryColor,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: AppColors.dividerColor,
        onChanged: (value) {
          setState(() => _isPrivateAccount = value);
        },
      ),
    );
  }

  Widget _buildChangeButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        'değiştir',
        style: TextStyle(
          color: AppColors.tertiaryColor,
          fontSize: 10.sp,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String label,
    String? value,
    Widget? trailing,
    bool showArrow = false,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 110.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.onBackgroundColor,
              height: 1.3,
            ),
          ),
        ),
        if (value != null)
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: valueColor ?? AppColors.onBackgroundColor,
              ),
            ),
          ),
        if (trailing != null) ...[
          SizedBox(width: 8.w),
          trailing,
        ],
        if (showArrow)
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.iconColor,
                size: 24.sp,
              ),
            ),
          ),
      ],
    );
  }
}
