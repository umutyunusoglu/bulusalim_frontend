import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart'; // Eklendi
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/session_state.dart';
import 'package:outnest/presentation/settings/view/change_password_page.dart'; // Eklendi
import 'package:outnest/presentation/settings/view/change_university_page.dart';
import 'package:outnest/presentation/settings/view/edit_social_media_link_page.dart';

class CommunityAccountSettingsPage extends StatefulWidget {
  const CommunityAccountSettingsPage({
    super.key,
  });

  @override
  State<CommunityAccountSettingsPage> createState() =>
      _CommunityAccountSettingsPageState();
}

class _CommunityAccountSettingsPageState
    extends State<CommunityAccountSettingsPage> {
  final SessionService _sessionService = getIt<SessionService>();

  Future<void> _editSocialLink(
    SocialLinkType type,
    String? currentValue,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSocialMediaLinkPage(
          linkType: type,
          initialValue:
              (currentValue == 'Link ekle' ||
                  currentValue == 'Belirtilmemiş' ||
                  currentValue == null)
              ? ''
              : currentValue,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SessionState>(
      valueListenable: _sessionService.stateListenable,
      builder: (context, session, child) {
        final currentUser = session.user;
        if (currentUser == null) return const SizedBox.shrink();

        final communityData = currentUser.communityData;

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundColor,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.iconColor,
                size: 26.sp,
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
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ÜNİVERSİTE VE DİĞER BİLGİLER ---
                _buildInfoRow(
                  label: 'Üniversite',
                  value: currentUser.university ?? 'Belirtilmemiş',
                  trailing: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangeUniversityPage(),
                        ),
                      );
                    },
                    child: Text(
                      'değiştir',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12.sp,
                        color: AppColors.secondaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                /*
                _buildInfoRow(
                  label: 'Telefon\nNumarası',
                  value: currentUser.phoneNumber ?? 'Belirtilmemiş',
                  showArrow: true,
                )*/
                _buildInfoRow(
                  label: 'Instagram',
                  value: (communityData?.instagramUrl?.isNotEmpty == true)
                      ? communityData!.instagramUrl!
                      : 'Link ekle',
                  valueColor: AppColors.locationBadgeText,
                  showArrow: true,
                  onTap: () => _editSocialLink(
                    SocialLinkType.instagram,
                    communityData?.instagramUrl,
                  ),
                ),
                _buildInfoRow(
                  label: 'Whatsapp',
                  value: (communityData?.whatsappUrl?.isNotEmpty == true)
                      ? communityData!.whatsappUrl!
                      : 'Link ekle',
                  valueColor: AppColors.locationBadgeText,
                  showArrow: true,
                  onTap: () => _editSocialLink(
                    SocialLinkType.whatsapp,
                    communityData?.whatsappUrl,
                  ),
                ),
                _buildInfoRow(
                  label: 'İletişim\nE-Postası',
                  value: (communityData?.contactEmail.isNotEmpty ?? false)
                      ? communityData!.contactEmail
                      : 'Link ekle',
                  valueColor: AppColors.locationBadgeText,
                  showArrow: true,
                  onTap: () => _editSocialLink(
                    SocialLinkType.email,
                    communityData?.contactEmail,
                  ),
                ),
                _buildInfoRow(
                  label: 'Web Sitesi',
                  value: (communityData?.websiteUrl.isNotEmpty ?? false)
                      ? communityData!.websiteUrl
                      : 'Link ekle',
                  valueColor: AppColors.locationBadgeText,
                  showArrow: true,
                  onTap: () => _editSocialLink(
                    SocialLinkType.website,
                    communityData?.websiteUrl,
                  ),
                ),

                SizedBox(height: 16.h),
                const Divider(color: AppColors.dividerColor, thickness: 1),
                SizedBox(height: 16.h),

                // --- HESAP GİZLİLİĞİ VE AÇIKLAMA ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hesap Gizliliği',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onBackgroundColor,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.9,
                      child: CupertinoSwitch(
                        value: currentUser.isPrivate,
                        onChanged: (val) async {
                          final updatedUser = currentUser.copyWith(
                            isPrivate: val,
                          );
                          await getIt<UserRepository>().updateUser(
                            updatedUser.userID,
                            {'isPrivate': val},
                          );
                          await _sessionService.refreshSession();
                        },
                        activeColor: AppColors.primaryColor,
                        trackColor: const Color(0xFFD1D1D6),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'Hesabın açıksa profilin ve paylaşımların herkes tarafından\ngörülebilir. Hesabını gizlediğinde ise paylaşımlarını yalnızca\nonayladığın kişiler görür. Profil fotoğrafın ve kullanıcı adın gibi\nbazı bilgiler her durumda herkese açıktır.',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textGrey,
                    height: 1.3,
                  ),
                ),

                SizedBox(height: 25.h),

                // --- HESAP TÜRÜ VE ŞİFRE ---
                _buildStandardActionRow(
                  label: 'Hesap Türü',
                  trailingText: 'Topluluk Hesabı',
                  onTap: () {
                    /* TODO: Hesap türü işlemleri */
                  },
                ),
                SizedBox(height: 4.h),
                _buildStandardActionRow(
                  label: 'Şifre Değiştir',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordPage(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
    Widget? trailing,
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            SizedBox(
              width: 100.w,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onBackgroundColor,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: valueColor ?? AppColors.onBackgroundColor,
                ),
              ),
            ),
            if (trailing != null) trailing,
            if (showArrow)
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

  Widget _buildStandardActionRow({
    required String label,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.onBackgroundColor,
              ),
            ),
            Row(
              children: [
                if (trailingText != null) ...[
                  Text(
                    trailingText,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGrey,
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                Icon(
                  Icons.chevron_right,
                  color: AppColors.iconColor,
                  size: 24.sp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
