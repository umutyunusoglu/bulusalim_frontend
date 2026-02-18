import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/services/file_service.dart';

class ParticipantsBottomSheet extends StatelessWidget {
  const ParticipantsBottomSheet({
    required this.creator,
    required this.participants,
    super.key,
  });

  final CompactUserEntity creator;
  final List<CompactUserEntity> participants;

  @override
  Widget build(BuildContext context) {
    // Creator hariç diğer katılımcılar
    final otherParticipants = participants
        .where((p) => p.userID != creator.userID)
        .toList();

    final totalCount = 1 + otherParticipants.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          SizedBox(height: 16.h),
          Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFF878787),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 28.h),

          // Başlık
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Buluşmaya Katılacak Kişiler ($totalCount)',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          SizedBox(height: 9.h),

          // Liste
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(bottom: 36.h),
              itemCount: totalCount,
              itemBuilder: (context, index) {
                final isCreatorItem = index == 0;

                final user = isCreatorItem
                    ? creator
                    : otherParticipants[index - 1];

                return _ParticipantTile(
                  user: user,
                  isCreator: isCreatorItem,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.user,
    required this.isCreator,
  });

  final CompactUserEntity user;
  final bool isCreator;

  @override
  Widget build(BuildContext context) {
    final hasUrl = user.profileImageUrl.isNotEmpty;
    final rawUrl = hasUrl
        ? user.profileImageUrl
        : FileService.defaultProfileImageUrl();

    // fixEmulatorUrl sadece ağdan gelen bir URL varsa çalışmalı
    final safeImageUrl = hasUrl ? fixEmulatorUrl(rawUrl) : rawUrl;

    return InkWell(
      onTap: () {
        context
          ..pop()
          ..push('/home/profile/${user.userID}');
      },
      child: Container(
        color: isCreator ? const Color(0xFFF9F9F9) : Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 9.h),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24.r,
              backgroundColor: Colors.grey.shade200,
              // Koşullu gösterim: URL varsa CachedNetworkImageProvider, yoksa AssetImage
              backgroundImage: hasUrl
                  ? CachedNetworkImageProvider(safeImageUrl)
                  : AssetImage(safeImageUrl) as ImageProvider,
              onBackgroundImageError: (_, __) {},
            ),
            SizedBox(width: 20.w),

            // Kullanıcı Adı
            Expanded(
              child: Text(
                user.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ),

            // Buluşma Sahibi Badge
            if (isCreator) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primaryColor,
                  ),
                  color: AppColors.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'buluşma sahibi',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12.sp,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
