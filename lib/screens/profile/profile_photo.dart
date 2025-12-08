// Dosya Yolu: lib/screens/profile/components/profile_photo.dart

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
    const glowColor = Color(0xFFFE6348);

    final double photoSize = 61.w;
    final double spreadSize = 4.5.w;
    final double badgeSize = 23.w;

    return Column(
      children: [
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
              profileImageUrl,
              fit: BoxFit.cover,
              width: photoSize,
              height: photoSize,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.person, color: Colors.grey, size: 24.w),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Rozetler
        SizedBox(
          height: badgeSize,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildBadgeSlots(badgeSize),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBadgeSlots(double size) {
    List<Widget> slots = [];
    const int totalSlots = 3;

    for (int i = 0; i < totalSlots; i++) {
      if (i < badgeUrls.length) {
        slots.add(
          _buildSingleBadge(isActive: true, imageUrl: badgeUrls[i], size: size),
        );
      } else {
        slots.add(_buildSingleBadge(isActive: false, size: size));
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
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? Colors.white
            : const Color(0xFF5B7A98).withOpacity(0.8),
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
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox(),
              ),
            )
          : null,
    );
  }
}
