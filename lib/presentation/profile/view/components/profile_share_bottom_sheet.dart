import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:outnest/app_router.dart';
import 'package:outnest/presentation/shared/share_content_bottom_sheet.dart';

class ProfileShareBottomSheet extends StatelessWidget {
  const ProfileShareBottomSheet({
    super.key,
    required this.username,
    required this.profileImageUrl,
    required this.profileUrl,
    required this.onSharePressed,
    required this.onInstagramSharePressed,
  });
  final String username;
  final String profileImageUrl;
  final String profileUrl;
  final VoidCallback onSharePressed;
  final Future<void> Function(Uint8List? stickerImageBytes)
      onInstagramSharePressed;

  @override
  Widget build(BuildContext context) {
    return ShareContentBottomSheet(
      title: username,
      subtitle: 'Profil bağlantısını paylaş',
      avatarImageUrl: profileImageUrl,
      shareUrl: profileUrl,
      shareButtonLabel: 'Profil Bağlantısını Paylaş',
      onSharePressed: onSharePressed,
      onInstagramSharePressed: onInstagramSharePressed,
      showScannerButton: true,
      scannerButtonLabel: 'QR Okut',
      onScannerPressed: () async {
        await router.push('/profile-scanner');
      },
    );
  }
}
