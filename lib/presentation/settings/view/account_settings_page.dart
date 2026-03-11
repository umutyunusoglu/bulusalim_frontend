import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/settings/view/change_account_type_page.dart';
import 'package:outnest/presentation/settings/view/change_password_page.dart';
import 'package:outnest/presentation/settings/view/change_phone_number_page.dart'; // Dosya ismine dikkat
import 'package:outnest/presentation/settings/view/change_university_page.dart';
import 'package:outnest/presentation/settings/view/connect_social_media_page.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late String _university;
  late String _phoneNumber;
  late String _socialMedia;
  late AccountType _accountType;
  late bool _isPrivateAccount;

  final UserRepository _userRepository = getIt<UserRepository>();
  final SessionService _sessionService = getIt<SessionService>();
  final AuthService _authService = getIt<AuthService>();

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında verileri yükle
    _loadUserData();
  }

  // Verileri set ettiğimiz metod
  void _loadUserData() {
    // BURASI ÖNEMLİ: Gerçek uygulamada buradaki verileri
    // UserProvider, Bloc veya API servisinden çekebilirsiniz.

    // Şimdilik örnek olması için statik verileri burada set ediyoruz:
    final currentUser = _sessionService.currentUser;
    if (currentUser == null) {
      setState(() {
        _university = 'Üniversite Seçilmedi';
        _phoneNumber = 'Telefon Numarası Eklenmedi';
        _socialMedia = 'Sosyal Medya Bağlanmadı';
        _accountType = AccountType.personal;
        _isPrivateAccount = false;
      });
      return;
    }

    final university = currentUser.university ?? 'Üniversite Seçilmedi';
    final phoneNumber = currentUser.phoneNumber ?? 'Telefon Numarası Eklenmedi';
    final accountType = currentUser.accountType ?? AccountType.personal;
    final isPrivateAccount = currentUser.isPrivate ?? false;

    setState(() {
      _university = university;
      _phoneNumber = phoneNumber;
      _accountType = accountType;
      _isPrivateAccount = isPrivateAccount;
    });
  }

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
            /*
            _buildPhoneSection(),
            SizedBox(height: 28.h),
            _buildSocialMediaSection(),
            SizedBox(height: 28.h),
            */
            _buildDivider(),
            SizedBox(height: 24.h),
            _buildPrivacySection(),
            SizedBox(height: 24.h),
            _buildDivider(),
            SizedBox(height: 24.h),
            _buildAccountTypeSection(),
            /*
            SizedBox(height: 28.h),
            _buildPasswordSection(),*/
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
      value: _accountType.value,
      showArrow: true,
      valueColor: AppColors.textGrey,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeAccountTypePage(
              currentType: _accountType.value,
            ),
          ),
        );

        if (result != null && result is String) {
          setState(() {
            _accountType = AccountType.fromString(result);
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
          _userRepository.updateUser(
            _sessionService.currentUser!.userID,
            {'isPrivate': value},
          );
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
