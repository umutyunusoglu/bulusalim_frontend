import 'package:bulusalim/core/utils/debug/android_image_url_fixer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfilePhoto extends StatelessWidget {
  final String profileImageUrl;
  final List<String> badgeUrls;

  const ProfilePhoto({
    super.key,
    required this.profileImageUrl,
    this.badgeUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    // TEMA BAĞLANTISI
    final theme = Theme.of(context);

    // Primary (Turuncu): Fotoğrafın arkasındaki glow efekti için
    final glowColor = theme.colorScheme.primary;

    // Secondary (Mavi): Pasif rozetlerin rengi için
    final inactiveBadgeColor = theme.colorScheme.secondary;

    final double photoSize = 61.w;
    final double spreadSize = 4.5.w;
    final double badgeSize = 23.w;

    return Column(
      children: [
        // 1. GLOW EFEKTLİ FOTOĞRAF
        Container(
          width: photoSize,
          height: photoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: 12,
                spreadRadius: spreadSize,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              fixEmulatorUrl(profileImageUrl),
              fit: BoxFit.cover,
              width: photoSize,
              height: photoSize,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.person, color: Colors.grey, size: 24.w),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // 2. ROZETLER
        SizedBox(
          height: badgeSize,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildBadgeSlots(badgeSize, inactiveBadgeColor),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBadgeSlots(double size, Color inactiveColor) {
    List<Widget> slots = [];
    const int totalSlots = 3;

    for (int i = 0; i < totalSlots; i++) {
      if (i < badgeUrls.length) {
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
    String? imageUrl,
    required double size,
    required Color inactiveColor,
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
              child: Image.network(
                fixEmulatorUrl(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox(),
              ),
            )
          : null,
    );
  }
}
