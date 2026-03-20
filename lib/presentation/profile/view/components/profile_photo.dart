import 'package:cached_network_image/cached_network_image.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/domain/services/file_service.dart';

class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({
    super.key,
    required this.profileImageUrl,
    required this.badgeUrls,
  });
  final String profileImageUrl;
  final List<String> badgeUrls;

  @override
  Widget build(BuildContext context) {
    // TEMA BAĞLANTISI
    final theme = Theme.of(context);

    // Primary (Turuncu): Fotoğrafın arkasındaki glow efekti için
    final glowColor = theme.colorScheme.primary;

    // Secondary (Mavi): Pasif rozetlerin rengi için
    final inactiveBadgeColor = theme.colorScheme.secondary;

    final photoSize = 65.w;
    final badgeSize = 23.w;

    final isNetwork =
        profileImageUrl.isNotEmpty && profileImageUrl.startsWith('http');

    return Column(
      children: [
        // 1. GLOW EFEKTLİ FOTOĞRAF
        Container(
          child: SizedBox(
            width: photoSize,
            height: photoSize,

            child: ClipOval(
              child: isNetwork
                  ? CachedNetworkImage(
                      imageUrl: fixEmulatorUrl(profileImageUrl),
                      fadeInDuration: Duration.zero,
                      fit: BoxFit.cover,
                      width: photoSize,
                      height: photoSize,
                      // İnternet varken yükleme hatası olursa asset'i bas
                      errorWidget: (context, url, error) {
                        debugPrint(
                          'ProfilePhoto Firebase image load failed: url=$url error=$error',
                        );
                        return Image.asset(
                          FileService.defaultProfileImageUrl(),
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      FileService.defaultProfileImageUrl(),
                      fit: BoxFit.cover,
                      width: photoSize,
                      height: photoSize,
                    ),
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // 2. ROZETLER
        /*
        SizedBox(
          height: badgeSize,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildBadgeSlots(badgeSize, inactiveBadgeColor),
          ),
        ),*/
      ],
    );
  }

  List<Widget> _buildBadgeSlots(double size, Color inactiveColor) {
    var slots = <Widget>[];
    const totalSlots = 3;

    for (var i = 0; i < totalSlots; i++) {
      if (i < badgeUrls.length) {
        print('Badge URL: ${badgeUrls[i]}');
        slots.add(
          _buildSingleBadge(
            isActive: true,
            imageUrl: badgeUrls[i],
            size: size,
            inactiveColor: inactiveColor,
          ),
        );
      } else {
        slots.add(
          _buildSingleBadge(
            isActive: false,
            size: size,
            inactiveColor: inactiveColor,
          ),
        );
      }

      if (i < totalSlots - 1) {
        slots.add(SizedBox(width: 4.w));
      }
    }
    return slots;
  }

  Widget _buildSingleBadge({
    required bool isActive,
    required double size,
    required Color inactiveColor,
    String? imageUrl,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.white : inactiveColor.withOpacity(0.8),
        border: Border.all(
          color: Colors.white,
          width: 1.w,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: isActive && imageUrl != null
          ? ClipOval(
              child: Image.asset(
                fixEmulatorUrl(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox(),
              ),
            )
          : null,
    );
  }
}
