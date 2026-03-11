import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityBottomSheet extends StatelessWidget {
  const CommunityBottomSheet({
    super.key,
    required this.instagram,
    required this.whatsapp,
    required this.website,
    required this.email,
  });

  final String instagram;
  final String whatsapp;
  final String website;
  final String email;

  // --- Ortak Launch Fonksiyonu (URL ve Email için) ---
  Future<void> _handleLaunch(String value, bool isEmail) async {
    if (value.isEmpty) return;
    Uri url = isEmail
        ? Uri(scheme: 'mailto', path: value)
        : Uri.parse(value.startsWith('http') ? value : 'https://$value');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: isEmail
              ? LaunchMode.platformDefault
              : LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Launch Hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _ContactModel(
        icon: 'assets/elements.png',
        value: instagram,
        hint: 'instagram adresi eklenmedi',
        isEmail: false,
      ),
      _ContactModel(
        icon: 'assets/whatsapp.png',
        value: whatsapp,
        hint: 'whatsapp grubu eklenmedi',
        isEmail: false,
      ),
      _ContactModel(
        icon: 'assets/link.png',
        value: website,
        hint: 'web sitesi eklenmedi',
        isEmail: false,
      ),
      _ContactModel(
        icon: 'assets/email.png',
        value: email,
        hint: 'e-posta adresi eklenmedi',
        isEmail: true,
      ),
    ];

    return Container(
      padding: EdgeInsets.only(
        top: 12.h,
        bottom: MediaQuery.of(context).padding.bottom + 24.h,
        left: 24.w,
        right: 24.w,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 24.h),
            decoration: BoxDecoration(
              color: AppColors.dividerColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Liste üzerinden dinamik üretim
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _ContactItem(
                iconPath: item.icon,
                text: item.value.isEmpty ? item.hint : item.value,
                onTap: item.value.isEmpty
                    ? null
                    : () => _handleLaunch(item.value, item.isEmail),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Yardımcı Model ---
class _ContactModel {
  final String icon;
  final String value;
  final String hint;
  final bool isEmail;

  _ContactModel({
    required this.icon,
    required this.value,
    required this.hint,
    required this.isEmail,
  });
}

// --- Alt Bileşen ---
class _ContactItem extends StatelessWidget {
  const _ContactItem({
    required this.iconPath,
    required this.text,
    this.onTap,
  });

  final String iconPath;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEmpty = onTap == null;
    final contentColor = isEmpty
        ? AppColors.textGrey.withOpacity(0.6)
        : AppColors.tertiaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: 20.r,
              height: 20.r,
              color: AppColors.tertiaryColor,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.link, size: 20.r, color: AppColors.tertiaryColor),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  color: contentColor,
                  fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w600,
                  fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
