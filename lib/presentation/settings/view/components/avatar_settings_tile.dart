import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/services/file_service.dart';

class AvatarSettingsTile extends StatelessWidget {
  const AvatarSettingsTile({
    super.key,
    required this.title,
    this.imageUrl,
    this.icon,
    required this.onTap,
  }) : assert(
         imageUrl != null || icon != null,
         'Ya resim (imageUrl) ya da ikon (icon) verilmelidir!',
       );
  final String title;
  final String? imageUrl;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget leadingWidget;

    if (icon != null) {
      // 1. DURUM: EĞER İKON VERİLMİŞSE
      leadingWidget = Container(
        width: 30.r,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 29.sp,
          color: AppColors.onBackgroundColor,
        ),
      );
    } else {
      // 2. DURUM: EĞER RESİM (IMAGE URL) VERİLMİŞSE
      final imgUrl = imageUrl ?? '';
      final hasUrl = imgUrl.startsWith('http') || imgUrl.startsWith('https');

      leadingWidget = CircleAvatar(
        radius: 16.r,
        backgroundColor: AppColors.dividerColor,
        backgroundImage: hasUrl
            ? CachedNetworkImageProvider(fixEmulatorUrl(imgUrl))
            : AssetImage(FileService.defaultProfileImageUrl()) as ImageProvider,
        onBackgroundImageError: (_, __) =>
            debugPrint('Resim yüklenemedi: $imgUrl'),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            leadingWidget,
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onBackgroundColor,
                ),
              ),
            ),
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
