import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:bulusalim/screens/settings/blocked_users_page.dart'; // YENİ EKLENDİ
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
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ayarlar',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
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

            Divider(height: 1, color: Colors.grey.shade200),
            SizedBox(height: 24.h),

            // --- GENEL AYARLAR ---
            const SettingsTile(
              title: 'Hesap Ayarları',
              subtitle: 'Gizlilik, üniversite, şifre, iletişim bilgileri',
            ),

            const SettingsTile(title: 'Kümeler'),
            const SettingsTile(title: 'Rozetler'),

            SettingsTile(
              title: 'Engellenen Kullanıcılar',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlockedUsersPage(),
                  ),
                );
              },
            ),

            SizedBox(height: 24.h),
            Divider(height: 1, color: Colors.grey.shade200),
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
            Divider(height: 1, color: Colors.grey.shade200),
            SizedBox(height: 24.h),

            // --- YASAL VE DESTEK ---
            const SettingsTile(title: 'Gizlilik Politikası'),
            const SettingsTile(title: 'Hizmet Şartları'),
            const SettingsTile(title: 'Destek ve Yardım'),

            SizedBox(height: 12.h),
            Divider(height: 1, color: Colors.grey.shade200),
            SizedBox(height: 24.h),

            // --- AKSİYONLAR ---
            SettingsTile(
              title: 'Hesabı Sil',
              titleColor: Colors.redAccent,
              showArrow: false,
              onTap: () {
                // Silme işlemi
              },
            ),
            SettingsTile(
              title: 'Çıkış Yap',
              titleColor: Colors.redAccent,
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

  // --- WIDGET'LAR ---

  Widget _buildProfileEditSection(BuildContext context) {
    final currentUser = getIt<SessionService>().currentUser;
    final profileImageUrl = currentUser?.profileImageUrl ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditProfilePage()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (profileImageUrl.isNotEmpty)
                  ? NetworkImage(profileImageUrl)
                  : null,
              child: (profileImageUrl.isEmpty)
                  ? Icon(Icons.person, color: Colors.grey, size: 24.sp)
                  : null,
            ),
            SizedBox(width: 12.w),
            Text(
              'Profili Düzenle',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.black, size: 24.sp),
          ],
        ),
      ),
    );
  }
}
