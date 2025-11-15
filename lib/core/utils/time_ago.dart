import 'package:flutter/material.dart';

class TimeAgo {
  static String format(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inSeconds < 60) return "şimdi";
    if (difference.inMinutes < 60) return "${difference.inMinutes} dk önce";
    if (difference.inHours < 24) return "${difference.inHours} sa önce";
    if (difference.inDays < 7) return "${difference.inDays} gün önce";
    return "${(difference.inDays / 7).floor()} hf önce";
  }
}
