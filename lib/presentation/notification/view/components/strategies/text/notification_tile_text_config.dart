import 'package:flutter/material.dart';

// Defines all text values rendered in a notification tile.
class NotificationTileTextConfig {
  const NotificationTileTextConfig({
    required this.title,
    required this.message,
    this.actionText,
    this.actionColor = const Color(0xFF2D8CFF),
  });

  // Bold leading segment (usually username or subject), shown first.
  final String title;

  // Main body sentence shown after title.
  final String message;

  // Optional CTA phrase appended after message (for example, "Buluşma kartını görüntüle").
  final String? actionText;

  // Color used when actionText is rendered.
  final Color actionColor;
}
