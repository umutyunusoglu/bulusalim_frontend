import 'package:cached_network_image/cached_network_image.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/domain/services/file_service.dart';

class BlockedUserTile extends StatelessWidget {
  const BlockedUserTile({
    required this.username,
    required this.profileImageUrl,
    required this.onUnblockTap,
    super.key,
  });

  final String username;
  final String profileImageUrl;
  final VoidCallback onUnblockTap;

  @override
  Widget build(BuildContext context) {
    final hasUrl =
        profileImageUrl.isNotEmpty && profileImageUrl.startsWith('http');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          // 1. AVATAR
          CircleAvatar(
            radius: 20.r,
            backgroundColor: Colors.grey.shade200,
            // URL varsa CachedNetworkImageProvider, yoksa Asset resmimiz
            backgroundImage: hasUrl
                ? CachedNetworkImageProvider(
                    fixEmulatorUrl(profileImageUrl),
                  )
                : AssetImage(FileService.defaultProfileImageUrl())
                      as ImageProvider,
            onBackgroundImageError: (_, __) => debugPrint('Avatar Load Error'),
          ),
          SizedBox(width: 12.w),

          // 2. KULLANICI ADI
          Expanded(
            child: Text(
              username,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),

          // 3. ENGELİ KALDIR BUTONU
          InkWell(
            onTap: onUnblockTap,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'engeli kaldır',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.tertiaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
