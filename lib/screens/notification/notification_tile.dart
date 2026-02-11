import 'package:cached_network_image/cached_network_image.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  // Sağ alttaki küçük ikon rozetinin tasarımı
  Widget _buildTypeBadge() {
    IconData icon;
    Color bgColor;
    // Varsayılan ikon rengi beyaz
    var iconColor = Colors.white;
    var iconSize = 10.sp;

    switch (notification.type) {
      case NotificationType.join:
        icon = Icons.waving_hand_rounded;
        bgColor = const Color(0xFF67C95F); //  Yeşil
      case NotificationType.invite:
        icon = Icons.mail_outline_rounded;
        bgColor = const Color(0xFF2D8CFF); // Mavis
      case NotificationType.cancel:
        icon = Icons.close_rounded;
        bgColor = const Color(0xFFFF3B30); // Kırmızı
      case NotificationType.updateTime:
      case NotificationType.updateLocation:
      case NotificationType.startingSoon:
      case NotificationType.earlyStart:
        icon = Icons.calendar_today_rounded;
        bgColor = const Color(0xFFFF9500); // Turuncu
        iconSize = 10.sp;
      case NotificationType.warning:
        return const SizedBox(); // Uyarıda küçük ikon yok, ana görsel değişiyor
      case NotificationType.badgeWin:
      case NotificationType.badgeProgress:
        return const SizedBox(); // Rozet bildiriminde küçük ikon yok
      default:
        icon = Icons.notifications;
        bgColor = Colors.grey;
    }

    return Container(
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
  }

  // Sol taraftaki Ana Görsel (Avatar veya İkon)
  Widget _buildMainAvatar() {
    // 1. DURUM: Sistem Uyarısı (Kırmızı Çerçeveli Ünlem)
    if (notification.type == NotificationType.warning) {
      return Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFF3B30), width: 1.5),
        ),
        child: Icon(
          Icons.priority_high_rounded,
          color: const Color(0xFFFF3B30),
          size: 24.sp,
        ),
      );
    }

    // 2. DURUM: Rozet Kazanımı (Pembe Daire İçinde Yazı)
    if (notification.type == NotificationType.badgeWin ||
        notification.type == NotificationType.badgeProgress) {
      return Container(
        width: 44.w,
        height: 44.w,
        decoration: const BoxDecoration(
          color: Color(0xFFF7C9C1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            'rozet',
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
      );
    }

    // 3. DURUM: Kullanıcı Fotoğrafı + Küçük Rozet
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44.w, // 44px Standart Avatar
          height: 44.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
            image: DecorationImage(
              // URL geçerliyse Network, değilse Asset kullan
              image:
                  (notification.avatarUrl.isNotEmpty &&
                      notification.avatarUrl.startsWith('http'))
                  ? CachedNetworkImageProvider(
                      fixEmulatorUrl(notification.avatarUrl),
                    )
                  : AssetImage(FileService.defaultProfileImageUrl())
                        as ImageProvider,
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
    // Özel Türkçe Kısa Formatını Aktif Et
    timeago.setLocaleMessages('tr_short', TrShortMessages());

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. GÖRSEL ALANI
            _buildMainAvatar(),

            SizedBox(width: 12.w),

            // 2. METİN ALANI
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12.sp,
                        color: Colors.black,
                        height: 1.3,
                      ),
                      children: [
                        // BAŞLIK (Kalın)
                        if (notification.title.isNotEmpty)
                          TextSpan(
                            text: '${notification.title} ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        // MESAJ (Normal)
                        TextSpan(
                          text: '${notification.message} ',
                          style: const TextStyle(fontWeight: FontWeight.w400),
                        ),
                        // AKSİYON METNİ
                        if (notification.actionText != null)
                          TextSpan(
                            text: notification.actionText,
                            style: const TextStyle(
                              color: AppColors.primaryColor, // Turuncu/Pembe
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                        // ZAMAN BİLGİSİ
                        TextSpan(
                          text: timeago.format(
                            notification.createdAt,
                            locale: 'tr_short',
                          ),
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 12.sp,
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

// --- ZAMAN FORMATI YARDIMCISI  ---
class TrShortMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';
  @override
  String prefixFromNow() => '';
  @override
  String suffixAgo() => ''; // "önce" kelimesi yok
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
