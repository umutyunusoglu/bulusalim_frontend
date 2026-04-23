import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/badges/badge_entity.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/presentation/badge/component/badge_details_dialog.dart';
import 'package:outnest/presentation/shared/network_svg.dart';

class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({
    super.key,
    required this.profileImageUrl,
    required this.pinnedBadges,
  });

  final String profileImageUrl;
  final List<BadgeEntity> pinnedBadges;

  @override
  Widget build(BuildContext context) {
    // TEMA BAĞLANTISI
    final theme = Theme.of(context);

    // Primary (Turuncu): Fotoğrafın arkasındaki glow efekti için

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
        SizedBox(
          height: badgeSize,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildBadgeSlots(context, badgeSize, inactiveBadgeColor),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBadgeSlots(
    BuildContext context,
    double size,
    Color inactiveColor,
  ) {
    var slots = <Widget>[];
    const totalSlots = 3;

    for (var i = 0; i < totalSlots; i++) {
      if (i < pinnedBadges.length) {
        final badge = pinnedBadges[i];
        slots.add(
          _buildSingleBadge(
            key: ValueKey(
              'badge_${badge.label}',
            ),
            context: context,
            isActive: true,
            badge: badge,
            size: size,
            inactiveColor: inactiveColor,
          ),
        );
      } else {
        slots.add(
          _buildSingleBadge(
            key: ValueKey('empty_slot_$i'),
            context: context,
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
    Key? key,
    required BuildContext context,
    required bool isActive,
    required double size,
    required Color inactiveColor,
    BadgeEntity? badge,
  }) {
    return GestureDetector(
      key: key,
      onTap: (isActive && badge != null)
          ? () {
              showDialog(
                context: context,
                builder: (context) => BadgeDetailsDialog(
                  badge: badge,
                  currentTier: badge.threshold,
                  isEarned: true,
                  safeThreshold: badge.threshold,
                ),
              );
            }
          : null,
      child: Container(
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
        child: (isActive && badge != null)
            ? ClipOval(
                child: NetworkSvg(
                  url: badge.iconURL,
                  width: size,
                  height: size,
                ),
              )
            : null,
      ),
    );
  }
}
