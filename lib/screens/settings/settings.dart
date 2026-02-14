import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/app_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/screens/settings/account_settings_page.dart';
import 'package:outnest/screens/settings/blocked_users_page.dart';
import 'package:outnest/screens/settings/delete_account_page.dart';
import 'package:outnest/screens/settings/device_permissons_page.dart';
import 'package:outnest/screens/settings/edit_profile_page.dart';
import 'package:outnest/screens/settings/settings_section_header.dart';
import 'package:outnest/screens/settings/settings_tile.dart';
import 'package:outnest/screens/settings/static_info_page.dart';
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
  bool _isBluetoothGranted = false;
  bool _isLocationGranted = false;
  bool _isCameraGranted = false;
  bool _isPhotosGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions(); // Sayfa açıldığında izinleri kontrol et
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Kullanıcı telefon ayarlarına gidip geri döndüğünde tetiklenir
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  // --- TÜM İZİNLERİ KONTROL EDEN MERKEZİ FONKSİYON ---
  Future<void> _checkAllPermissions() async {
    final notif = await Permission.notification.status;
    final blue = await Permission.bluetooth.status;
    final loc = await Permission.location.status;
    final cam = await Permission.camera.status;
    final photo = await Permission.photos.status;

    if (mounted) {
      setState(() {
        _isNotifGranted = notif.isGranted || notif.isLimited;
        _isBluetoothGranted = blue.isGranted || blue.isLimited;
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
    // Sayfadan geri dönüldüğünde stateleri güncelle
    await _checkAllPermissions();
  }

  // --- POPUP FONKSİYONU ---
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
                      getIt<AuthService>().signOut();
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
    final currentUser = getIt<SessionService>().currentUser;
    final profileImageUrl = currentUser?.profileImageUrl ?? '';

    // Metinleri statelere göre dinamik belirlemek için yardımcı
    String getStatusText(bool isGranted) =>
        isGranted ? 'izin verildi' : 'izin verilmedi';

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ayarlar',
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
          children: [
            // --- PROFİLİ DÜZENLE ---
            _buildProfileEditSection(context, profileImageUrl),

            SizedBox(height: 24.h),
            const Divider(height: 1, color: AppColors.dividerColor),
            SizedBox(height: 24.h),

            // --- GENEL AYARLAR ---
            SettingsTile(
              title: 'Hesap Ayarları',
              subtitle: 'Gizlilik, üniversite, iletişim bilgileri',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountSettingsPage(),
                  ),
                );
              },
            ),

            SettingsTile(
              title: 'Engellenen Kullanıcılar',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlockedUsersPage()),
                );
              },
            ),

            SizedBox(height: 24.h),
            const Divider(height: 1, color: AppColors.dividerColor),
            SizedBox(height: 24.h),

            // --- CİHAZ İZİNLERİ ---
            const SettingsSectionHeader(title: 'Cihaz İzinleri'),

            SettingsTile(
              title: 'Bildirimler',
              trailingText: getStatusText(_isNotifGranted), // DİNAMİK
              onTap: () => _navigateToPermissionDetail(
                title: 'Bildirimler',
                description:
                    'Outnest uygulamasına bu cihaza güncellemeler ve önemli bildirimler göndermesine izin verilir.',
                permission: Permission.notification,
              ),
            ),
            /*
            SettingsTile(
              title: 'Bluetooth',
              trailingText: getStatusText(_isBluetoothGranted), // DİNAMİK
              onTap: () => _navigateToPermissionDetail(
                title: 'Bluetooth',
                description:
                    "Outnest uygulamasına yakındaki cihazlarla bağlantı kurmak için Bluetooth'u kullanmasına izin verilir.",
                permission: Permission.bluetooth,
              ),
            ),*/
            SettingsTile(
              title: 'Konum Servisleri',
              trailingText: getStatusText(_isLocationGranted), // DİNAMİK
              onTap: () => _navigateToPermissionDetail(
                title: 'Konum Servisleri',
                description:
                    'Outnest uygulamasına bulunduğun konuma göre içerik ve öneriler sunmak için konum bilgine erişmesine izin verilir.',
                permission: Permission.location,
              ),
            ),
            SettingsTile(
              title: 'Kamera',
              trailingText: getStatusText(_isCameraGranted), // DİNAMİK
              onTap: () => _navigateToPermissionDetail(
                title: 'Kamera',
                description:
                    'Outnest uygulamasında fotoğraf çekmek ve paylaşmak için kameranıza erişim izni verilir.',
                permission: Permission.camera,
              ),
            ),
            SettingsTile(
              title: 'Fotoğraflar',
              trailingText: getStatusText(_isPhotosGranted), // DİNAMİK
              onTap: () => _navigateToPermissionDetail(
                title: 'Fotoğraflar',
                description:
                    'Outnest uygulamasının galerinizdeki fotoğrafları seçip yükleyebilmesi için erişim izni verilir.',
                permission: Permission.photos,
              ),
            ),

            SizedBox(height: 12.h),
            const Divider(height: 1, color: AppColors.dividerColor),
            SizedBox(height: 24.h),

            // --- YASAL VE DESTEK ---
            SettingsTile(
              title: 'Gizlilik Politikası',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StaticInfoPage(
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
            SettingsTile(
              title: 'Hizmet Şartları',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StaticInfoPage(
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
            SettingsTile(
              title: 'Destek ve Yardım',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StaticInfoPage(
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

            SizedBox(height: 12.h),
            const Divider(height: 1, color: AppColors.dividerColor),
            SizedBox(height: 24.h),

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

            // --- ÇIKIŞ YAP  ---
            GestureDetector(
              onTap: () => _showLogoutDialog(context),
              behavior: HitTestBehavior.opaque,
              child: const SettingsTile(
                title: 'Çıkış Yap',
                titleColor: AppColors.primaryColor,
                showArrow: false,
              ),
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileEditSection(
    BuildContext context,
    String profileImageUrl,
  ) {
    final hasUrl =
        profileImageUrl.isNotEmpty && profileImageUrl.startsWith('http');

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProfilePage()),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: AppColors.dividerColor,
              backgroundImage: hasUrl
                  ? CachedNetworkImageProvider(
                      fixEmulatorUrl(profileImageUrl),
                    )
                  : AssetImage(FileService.defaultProfileImageUrl())
                        as ImageProvider,
              onBackgroundImageError: (_, __) =>
                  debugPrint('Avatar Load Error'),
            ),
            SizedBox(width: 12.w),
            Text(
              'Profili Düzenle',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.onBackgroundColor,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: AppColors.iconColor,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }
}
