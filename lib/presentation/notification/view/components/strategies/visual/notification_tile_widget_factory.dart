import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/notification_tile_visual_config.dart';

class NotificationTileWidgetFactory {
  Widget buildLeading(
    NotificationEntity notification,
    NotificationTileVisualConfig config,
  ) {
    if (config.useWarningAvatar) {
      return Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFF3B30), width: 1.5),
        ),
        child: Icon(
          Icons.priority_high_rounded,
          color: const Color(0xFFFF3B30),
          size: 24.sp,
        ),
      );
    }

    if (config.useBadgeAvatar) {
      return Container(
        width: 44.w,
        height: 44.w,
        decoration: const BoxDecoration(
          color: Color(0xFFF7C9C1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            config.badgeAvatarLabel,
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
            image: DecorationImage(
              image:
                  (notification.profileImageUrl.isNotEmpty &&
                      notification.profileImageUrl.startsWith('http'))
                  ? CachedNetworkImageProvider(
                      fixEmulatorUrl(notification.profileImageUrl),
                    )
                  : AssetImage(FileService.defaultProfileImageUrl())
                        as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: _buildBadge(config),
        ),
      ],
    );
  }

  Widget _buildBadge(NotificationTileVisualConfig config) {
    if (config.hideBadge ||
        config.badgeIcon == null ||
        config.badgeColor == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        color: config.badgeColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Icon(
          config.badgeIcon,
          size: config.badgeIconSizeSp.sp,
          color: config.badgeIconColor,
        ),
      ),
    );
  }
}
