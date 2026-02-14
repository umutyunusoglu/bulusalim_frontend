import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.notification,
    required this.onTap,
    super.key,
  });

  final NotificationEntity notification;
  final VoidCallback onTap;

  Widget _buildTypeBadge() {
    // mevcut badge mantığınız burada kalabilir; örnek basit:
    if (notification.type == NotificationType.warning) return const SizedBox();
    return Container(
      width: 18.w,
      height: 18.w,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Icon(Icons.notifications, size: 10.sp, color: Colors.white),
      ),
    );
  }

  Widget _buildMainAvatar() {
    // Uygulamamızdaki resolved avatarUrl (repo zaten http/https dönmüş olmalı)
    final raw = (notification.avatarUrl ?? '').trim();

    final bool isNetwork =
        raw.isNotEmpty &&
        (raw.startsWith('http://') ||
            raw.startsWith('https://') ||
            raw.contains('firebasestorage.googleapis.com'));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
          ),
          child: ClipOval(
            child: isNetwork
                ? CachedNetworkImage(
                    imageUrl: fixEmulatorUrl(raw),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade100,
                      child: Icon(
                        Icons.person,
                        color: Colors.grey.shade300,
                        size: 20.sp,
                      ),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
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
        Positioned(
          right: -2,
          bottom: -2,
          child: _buildTypeBadge(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('tr_short', TrShortMessages());

    // Debug: gelen avatar url'yi görmek isterseniz açın
    // print('Notification avatarUrl: ${notification.avatarUrl}');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center, // ÖNEMLİ: dikey ortalama
          children: [
            _buildMainAvatar(),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min, // içerik kadar yükseklik
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 13.sp,
                        color: Colors.black,
                        height: 1.3,
                      ),
                      children: [
                        if ((notification.title ?? '').isNotEmpty)
                          TextSpan(
                            text: '${notification.title} ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        TextSpan(
                          text: '${notification.message ?? ''} ',
                          style: const TextStyle(fontWeight: FontWeight.w400),
                        ),
                        TextSpan(
                          text:
                              ' ${timeago.format(notification.createdAt, locale: 'tr_short')}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
