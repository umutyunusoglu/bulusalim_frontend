import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/app_router.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/groups/view/groups_page.dart';
import 'package:outnest/presentation/settings/view/about_community_page.dart';
import 'package:outnest/presentation/settings/view/blocked_users_page.dart';
import 'package:outnest/presentation/settings/view/components/avatar_settings_tile.dart';
import 'package:outnest/presentation/settings/view/components/settings_section_header.dart';
import 'package:outnest/presentation/settings/view/components/settings_tile.dart';
import 'package:outnest/presentation/settings/view/components/static_info_widget.dart';
import 'package:outnest/presentation/settings/view/delete_account_page.dart';
import 'package:outnest/presentation/settings/view/device_permissons_page.dart';
import 'package:outnest/presentation/settings/view/edit_profile_page.dart';
import 'package:outnest/presentation/shared/city_selection_dialog.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  // --- İZİN DURUMLARI ---
  bool _isNotifGranted = false;
  bool _isLocationGranted = false;
  bool _isCameraGranted = false;
  bool _isPhotosGranted = false;
  String? _updatedCity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    final notif = await Permission.notification.status;
    final loc = await Permission.location.status;
    final cam = await Permission.camera.status;
    final photo = await Permission.photos.status;

    if (mounted) {
      setState(() {
        _isNotifGranted = notif.isGranted || notif.isLimited;
        _isLocationGranted = loc.isGranted || loc.isLimited;
        _isCameraGranted = cam.isGranted || cam.isLimited;
        _isPhotosGranted = photo.isGranted || photo.isLimited;
      });
    }
  }

  Future<void> _navigateToPermissionDetail({
    required String title,
    required String description,
    required Permission permission,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DevicePermissionsPage(
          title: title,
          description: description,
          permission: permission,
        ),
      ),
    );
    await _checkAllPermissions();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hesabından çıkış yapmak istediğine\nemin misin?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onBackgroundColor,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: 173.w,
                  height: 40.h,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      unawaited(getIt<AuthService>().signOut().run());
                      if (context.mounted) {
                        router.go('/welcome');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                    ),
                    child: Text(
                      'Çıkış Yap',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. SessionService üzerinden kullanıcıyı alıyoruz
    final currentUser = getIt<SessionService>().currentUser;

    final isCommunity = currentUser?.accountType == AccountType.community;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.iconColor,
            size: 24,
          ),
          onPressed: () {
            try {
              context.pop();
            } catch (e) {
              context.go('/home');
            }
          },
        ),
        title: Text(
          isCommunity ? 'Topluluk Ayarları' : 'Ayarlar',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.onBackgroundColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildSettingsContent(currentUser),
        ),
      ),
    );
  }

  // DİNAMİK LİSTE ÜRETİCİSİ
  List<Widget> _buildSettingsContent(UserEntity? currentUser) {
    final isCommunity = currentUser?.accountType == AccountType.community;
    final profileImageUrl = currentUser?.profileImageUrl ?? '';

    final userCity =
        _updatedCity ??
        ((currentUser?.city != null && currentUser!.city!.trim().isNotEmpty)
            ? currentUser.city!
            : 'Seçilmedi');

    final content = <Widget>[
      SizedBox(height: 8.h),
      // 1. ÜST KISIM: PROFİLİ DÜZENLE
      AvatarSettingsTile(
        title: 'Profili Düzenle',
        imageUrl: profileImageUrl,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfilePage()),
          );
        },
      ),
    ];

    // 2. SADECE TOPLULUK İSE: TOPLULUK HAKKINDA
    if (isCommunity) {
      content.add(
        AvatarSettingsTile(
          title: 'Topluluk Hakkında',
          icon: Icons.info_outline_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutCommunityPage()),
            );
          },
        ),
      );
    }
    content
      ..add(SizedBox(height: 16.h))
      ..add(const Divider(height: 1, color: AppColors.dividerColor))
      ..add(SizedBox(height: 16.h))
      // 3. ORTA KISIM (Hesap Ayarları, Kümeler, Rozetler, Engellenenler)
      ..add(
        SettingsTile(
          title: isCommunity ? 'Topluluk Hesap Ayarları' : 'Hesap Ayarları',
          subtitle:
              'Gizlilik, üniversite, şifre, iletişim bilgileri, hesap türü',
          onTap: () {
            context.push('/settings/edit-account');
          },
        ),
      )
      ..add(
        InkWell(
          onTap: () async {
            final returnedCity = await showDialog<String>(
              context: context,
              builder: (context) =>
                  const CitySelectionDialog(isDismissible: true),
            );

            if (returnedCity != null && mounted) {
              setState(() {
                _updatedCity = returnedCity;
              });
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Şehir',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onBackgroundColor,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      userCity,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textGrey,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.black,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                  ],
                ),
              ],
            ),
          ),
        ),
      )
      ..add(
        SettingsTile(
          title: 'Kümeler',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupsPage()),
            );
          },
        ),
      )
      /*
      ..add(
        SettingsTile(
          title: 'Rozetler',
          onTap: () {
            // TODO: Rozetler sayfasına yönlendir
          },
        ),
      )*/
      ..add(
        SettingsTile(
          title: 'Engellenen Kullanıcılar',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BlockedUsersPage()),
            );
          },
        ),
      )
      ..add(SizedBox(height: 24.h))
      ..add(const Divider(height: 1, color: AppColors.dividerColor))
      ..add(SizedBox(height: 24.h))
      // 4. ALT KISIM: CİHAZ İZİNLERİ
      ..add(const SettingsSectionHeader(title: 'Cihaz İzinleri'))
      ..add(
        SettingsTile(
          title: 'Bildirimler',
          onTap: () => _navigateToPermissionDetail(
            title: 'Bildirimler',
            description:
                'Outnest uygulamasına bu cihaza güncellemeler ve önemli bildirimler göndermesine izin verilir.',
            permission: Permission.notification,
          ),
        ),
      )
      ..add(
        SettingsTile(
          title: 'Konum Servisleri',
          onTap: () => _navigateToPermissionDetail(
            title: 'Konum Servisleri',
            description:
                'Outnest uygulamasına bulunduğun konuma göre içerik ve öneriler sunmak için konum bilgine erişmesine izin verilir.',
            permission: Permission.location,
          ),
        ),
      )
      ..add(
        SettingsTile(
          title: 'Kamera',
          onTap: () => _navigateToPermissionDetail(
            title: 'Kamera',
            description:
                'Outnest uygulamasında fotoğraf çekmek ve paylaşmak için kameranıza erişim izni verilir.',
            permission: Permission.camera,
          ),
        ),
      )
      ..add(
        SettingsTile(
          title: 'Fotoğraflar',
          onTap: () => _navigateToPermissionDetail(
            title: 'Fotoğraflar',
            description:
                'Outnest uygulamasının galerinizdeki fotoğrafları seçip yükleyebilmesi için erişim izni verilir.',
            permission: Permission.photos,
          ),
        ),
      )
      ..add(SizedBox(height: 12.h))
      ..add(const Divider(height: 1, color: AppColors.dividerColor))
      ..add(SizedBox(height: 24.h))
      // 5. EN ALT: YASAL, SİLME VE ÇIKIŞ YAP
      ..add(
        SettingsTile(
          title: 'Gizlilik Politikası',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StaticInfoWidget(
                  title: 'Gizlilik Politikası',
                  content:
                      'Outnest’te verilerinin nasıl toplandığını, kullanıldığını ve korunduğunu buradan öğrenebilirsin.',
                  linkText:
                      'Gizlilik ve veri kullanımı hakkında daha fazla bilgi al',
                  linkUrl: 'https://outnest.app/yasal/gizlilik-politikasi',
                ),
              ),
            );
          },
        ),
      )
      ..add(
        SettingsTile(
          title: 'Hizmet Şartları',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StaticInfoWidget(
                  title: 'Hizmet Şartları',
                  content:
                      'Outnest’i kullanırken geçerli olan kurallar ve sorumluluklar hakkında buradan bilgi edinebilirsin.',
                  linkText:
                      'Hizmet şartları ve kullanım koşulları hakkında daha fazla bilgi al',
                  linkUrl: 'https://outnest.app/yasal/hizmet-kosullari',
                ),
              ),
            );
          },
        ),
      )
      ..add(
        SettingsTile(
          title: 'Destek ve Yardım',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StaticInfoWidget(
                  title: 'Destek ve Yardım',
                  content:
                      'Outnest ile ilgili soruların mı var? Yardım almak ve destek talep etmek için buraya göz atabilirsin.',
                  linkText: 'Destek ve yardım sayfasına git',
                  linkUrl: 'https://outnest.app/',
                ),
              ),
            );
          },
        ),
      )
      ..add(SizedBox(height: 12.h))
      ..add(const Divider(height: 1, color: AppColors.dividerColor))
      ..add(SizedBox(height: 24.h))
      ..add(
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeleteAccountPage()),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: const SettingsTile(
            title: 'Hesabı Sil',
            titleColor: AppColors.primaryColor,
            showArrow: false,
          ),
        ),
      )
      ..add(
        GestureDetector(
          onTap: () => _showLogoutDialog(context),
          behavior: HitTestBehavior.opaque,
          child: const SettingsTile(
            title: 'Çıkış Yap',
            titleColor: AppColors.primaryColor,
            showArrow: false,
          ),
        ),
      )
      ..add(SizedBox(height: 40.h));

    return content;
  }
}
