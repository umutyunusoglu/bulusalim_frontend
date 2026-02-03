import 'package:cached_network_image/cached_network_image.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/services/file_service.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    required this.message,
    required this.time,
    required this.isCurrentUser,
    this.username,
    this.userAvatarUrl,
    super.key,
  });

  final String message;
  final String time;
  final bool isCurrentUser;
  final String? username;
  final String? userAvatarUrl;

  @override
  Widget build(BuildContext context) {
    // 1. Durum:  Mevcut Kullanıcı
    if (isCurrentUser) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Mesaj Balonu
                Container(
                  constraints: BoxConstraints(
                    maxWidth: 247.w,
                  ),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.salmonPink.withOpacity(0.25),
                    borderRadius: BorderRadius.all(
                      Radius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 14.sp,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),

                Text(
                  time,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 11.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. Durum: Diğer Kullanıcı
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (24x24)
          ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: SizedBox(
              width: 24.w,
              height: 24.w,
              child:
                  (userAvatarUrl != null && userAvatarUrl!.startsWith('http'))
                  ? CachedNetworkImage(
                      imageUrl: fixEmulatorUrl(
                        userAvatarUrl!,
                      ), // Emulator fix'i unutma
                      fadeInDuration: Duration.zero,
                      fit: BoxFit.cover,
                      // İnternet varken ama resim yüklenemezse (404 vs.)
                      errorWidget: (context, error, stackTrace) => Image.asset(
                        FileService.defaultProfileImageUrl(),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      FileService.defaultProfileImageUrl(),
                      fit: BoxFit.cover,
                    ),
            ),
          ),

          SizedBox(width: 12.w), // Avatar ile balon arası boşluk
          // Mesaj ve Alt Bilgiler
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mesaj Balonu
              Container(
                constraints: BoxConstraints(maxWidth: 247.w),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4.r),
                    topRight: Radius.circular(16.r),
                    bottomLeft: Radius.circular(16.r),
                    bottomRight: Radius.circular(16.r),
                  ),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14.sp,
                    color: AppColors.darkSlate,
                    height: 1.4,
                  ),
                ),
              ),

              SizedBox(height: 4.h),

              // Kullanıcı Adı ve Saat (Balonun genişliği kadar alana yayılır)
              SizedBox(
                width: 247.w, // Balon genişliğiyle aynı hizada olması için
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Kullanıcı Adı
                    Expanded(
                      child: Text(
                        username ?? 'Kullanıcı',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Saat
                    Text(
                      time,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 11.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
