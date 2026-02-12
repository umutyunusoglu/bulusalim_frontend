import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/domain/entities/notification/follow_notification_entity.dart';
import 'package:outnest/domain/entities/user/friend_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class FollowRequestTile extends StatelessWidget {
  FollowRequestTile({required this.item, super.key});

  final FollowNotificationEntity item;
  final LoggingService _logger = getIt<LoggingService>();

  // Sağ taraftaki aksiyon butonlarını oluşturur
  Widget _buildTrailingAction() {
    switch (item.status) {
      // DURUM 1: Takip Ediliyor
      case FollowStatus.following:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            'takip ediliyor',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.tertiaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );

      // DURUM 2: İstek Gönderildi
      case FollowStatus.sent:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            'istek gönderildi',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.tertiaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );

      // DURUM 3: Takip Et
      case FollowStatus.none:
        return GestureDetector(
          onTap: () async {
            // TODO: Takip etme işlemi
            _logger.info('Takip et butonuna tıklandı: ${item.username}');

            final sessionService = getIt<SessionService>();
            final userRepository = getIt<UserRepository>();

            final targetUserID = item.userID;
            final currentUser = sessionService.currentUser;

            final targetUser = await userRepository.getCurrentUser(
              targetUserID,
            );

            if (targetUser!.isPrivate) {
              // Özel hesap, takip isteği gönder
              _logger.info(
                'Özel hesaba takip isteği gönderiliyor: ${targetUser.username}',
              );

              await userRepository.sendFollowRequest(
                currentUser!.userID,
                targetUserID,
                true,
              );
            }
          },

          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'takip et',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );

      // DURUM 4: Kabul Et / Sil
      case FollowStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                final sessionService = getIt<SessionService>();
                final userRepository = getIt<UserRepository>();

                final targetUserID = item.userID;
                final currentUser = sessionService.currentUser;

                final follower = FriendEntity(
                  userID: targetUserID,
                  username: item.username,
                  profileImageUrl: item.profileImageUrl,
                  createdAt: DateTime.now(),
                );

                userRepository.addFollower(currentUser!.userID, follower);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'kabul et',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            SizedBox(width: 4.w),
            GestureDetector(
              onTap: () {
                // TODO: Silme işlemi
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'sil',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.tertiaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Özel formatı ('tr_short') sisteme tanıtıyoruz
    timeago.setLocaleMessages('tr_short', TrShortMessages());
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // 1. AVATAR
          CircleAvatar(
            radius: 16.r,
            backgroundColor:
                Colors.grey.shade200, // Resim yüklenene kadar boş kalmasın
            backgroundImage:
                (item.profileImageUrl.isNotEmpty &&
                    item.profileImageUrl.startsWith('http'))
                ? CachedNetworkImageProvider(
                    fixEmulatorUrl(item.profileImageUrl),
                  )
                : AssetImage(FileService.defaultProfileImageUrl())
                      as ImageProvider,
            onBackgroundImageError: (_, __) => debugPrint('Small Avatar Error'),
          ),
          SizedBox(width: 12.w),

          // 2. METİN
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12.sp,
                  color: Colors.black,
                  height: 1.3,
                ),
                children: [
                  TextSpan(
                    text: '${item.username} ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: item.message.replaceAll('\n', ' ').trim(),
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                  // Zaman Bilgisi
                  TextSpan(
                    text:
                        ' ${timeago.format(item.createdAt, locale: 'tr_short')}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. BUTONLAR
          _buildTrailingAction(),
        ],
      ),
    );
  }
}

class TrShortMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';
  @override
  String prefixFromNow() => '';
  @override
  String suffixAgo() => '';
  @override
  String suffixFromNow() => '';
  @override
  String lessThanOneMinute(int seconds) => 'şimdi';
  @override
  String aboutAMinute(int minutes) => '1dk';
  @override
  String minutes(int minutes) => '${minutes}dk';
  @override
  String aboutAnHour(int minutes) => '1sa';
  @override
  String hours(int hours) => '${hours}sa';
  @override
  String aDay(int hours) => '1gn';
  @override
  String days(int days) => '${days}gn';
  @override
  String aboutAMonth(int days) => '1ay';
  @override
  String months(int months) => '${months}ay';
  @override
  String aboutAYear(int year) => '1yl';
  @override
  String years(int years) => '${years}yl';
  @override
  String wordSeparator() => ' ';
}
