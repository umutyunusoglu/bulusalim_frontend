import 'package:flutter/material.dart';

class NotificationTileVisualConfig {
  const NotificationTileVisualConfig({
    this.badgeIcon,
    this.badgeColor,
    this.badgeIconColor = Colors.white,
    this.badgeIconSizeSp = 10,
    this.hideBadge = false,
    this.useWarningAvatar = false,
    this.useBadgeAvatar = false,
    this.badgeAvatarLabel = 'rozet',
  });

  final IconData? badgeIcon;
  final Color? badgeColor;
  final Color badgeIconColor;
  final double badgeIconSizeSp;
  final bool hideBadge;
  final bool useWarningAvatar;
  final bool useBadgeAvatar;
  final String badgeAvatarLabel;
}
