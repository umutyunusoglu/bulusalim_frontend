import 'package:cached_network_image/cached_network_image.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/domain/services/file_service.dart';

class EventAvatarBadge extends StatelessWidget {
  const EventAvatarBadge({
    required this.imageUrl,
    this.categoryIcon,
    super.key,
  });

  final String imageUrl;
  final String? categoryIcon;

  @override
  Widget build(BuildContext context) {
    // URL kontrolü
    final hasValidUrl = imageUrl.isNotEmpty;
    // Kategori ikonu
    final displayIcon = categoryIcon ?? '🎉';

    return SizedBox(
      width: 50.w,
      height: 50.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // --- 1. ANA PROFIL RESMİ ---
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: (imageUrl.startsWith('http'))
                  ? CachedNetworkImage(
                      imageUrl: fixEmulatorUrl(imageUrl),
                      fadeInDuration: Duration.zero,
                      fit: BoxFit.cover,
                      memCacheHeight: 100, // RAM dostu
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) => Center(
                            child: SizedBox(
                              width: 15.w,
                              height: 15.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                      errorWidget: (context, url, error) => Image.asset(
                        FileService.defaultProfileImageUrl(), // Fallback resmi
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      FileService.defaultProfileImageUrl(), // URL yoksa direkt bunu bas
                      fit: BoxFit.cover,
                    ),
            ),
          ),

          // --- 2. SAĞ ALT AKTİVİTE ROZETİ ---
          Positioned(
            right: -6.w, // Sağa doğru dışarı taşma
            bottom: -3.w, // Hafif aşağı
            child: Container(
              width: 24.w,
              height: 24.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Text(
                  displayIcon,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: AppColors.lightCloud,
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        color: AppColors.textGrey.withOpacity(0.5),
        size: 24.sp,
      ),
    );
  }
}
