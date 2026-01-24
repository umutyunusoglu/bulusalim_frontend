import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:bulusalim/screens/settings/acoount_settings_page.dart';
import 'package:bulusalim/screens/settings/blocked_users_page.dart';
import 'package:bulusalim/screens/settings/edit_profile_page.dart';
import 'package:bulusalim/screens/settings/settings_section_header.dart';
import 'package:bulusalim/screens/settings/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            _buildProfileEditSection(context),
            SizedBox(height: 24.h),

            Divider(height: 1, color: AppColors.dividerColor),
            SizedBox(height: 24.h),

            // --- GENEL AYARLAR ---
            SettingsTile(
              title: 'Hesap Ayarları',
              subtitle: 'Gizlilik, üniversite, şifre, iletişim bilgileri',
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
                  MaterialPageRoute(
                    builder: (_) => const BlockedUsersPage(),
                  ),
                );
              },
            ),

            SizedBox(height: 24.h),
            const Divider(height: 1, color: AppColors.dividerColor),
            SizedBox(height: 24.h),

            // --- CİHAZ İZİNLERİ ---
            const SettingsSectionHeader(title: 'Cihaz İzinleri'),

            const SettingsTile(
              title: 'Bildirimler',
              trailingText: 'izin verildi',
            ),
            const SettingsTile(
              title: 'Bluetooth',
              trailingText: 'izin verildi',
            ),
            const SettingsTile(
              title: 'Konum Servisleri',
              trailingText: 'izin verildi',
            ),
            const SettingsTile(title: 'Kamera', trailingText: 'izin verildi'),
            const SettingsTile(
              title: 'Fotoğraflar',
              trailingText: 'izin verilmedi',
            ),

            SizedBox(height: 12.h),
            const Divider(height: 1, color: AppColors.dividerColor),
            SizedBox(height: 24.h),

            // --- YASAL VE DESTEK ---
            const SettingsTile(title: 'Gizlilik Politikası'),
            const SettingsTile(title: 'Hizmet Şartları'),
            const SettingsTile(title: 'Destek ve Yardım'),

            SizedBox(height: 12.h),
            const Divider(height: 1, color: AppColors.dividerColor),
            SizedBox(height: 24.h),

            // --- AKSİYONLAR ---
            SettingsTile(
              title: 'Hesabı Sil',
              titleColor: AppColors.primaryColor,
              showArrow: false,
              onTap: () {
                // Silme işlemi
              },
            ),
            SettingsTile(
              title: 'Çıkış Yap',
              titleColor: AppColors.primaryColor,
              showArrow: false,
              onTap: () {
                // Çıkış işlemi
              },
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileEditSection(BuildContext context) {
    final currentUser = getIt<SessionService>().currentUser;
    final profileImageUrl = currentUser?.profileImageUrl ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProfilePage()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: AppColors.dividerColor,
              backgroundImage: (profileImageUrl.isNotEmpty)
                  ? NetworkImage(profileImageUrl)
                  : null,
              child: (profileImageUrl.isEmpty)
                  ? Icon(Icons.person, color: AppColors.textGrey, size: 24.sp)
                  : null,
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
            Icon(Icons.chevron_right, color: AppColors.iconColor, size: 24.sp),
          ],
        ),
      ),
    );
  }
}
