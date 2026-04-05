import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/presentation/notification/view/components/strategies/notification_tile_composition.dart';
import 'package:outnest/presentation/notification/view/components/strategies/visual/notification_tile_widget_factory.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.notification,
    required this.onTap,
    required this.composition,
    super.key,
  });

  final NotificationEntity notification;
  final VoidCallback onTap;
    final NotificationTileComposition composition;
  static final NotificationTileWidgetFactory _widgetFactory =
      NotificationTileWidgetFactory();
  static bool _timeagoLocaleRegistered = false;

  static void _ensureTimeagoLocaleRegistered() {
    if (_timeagoLocaleRegistered) return;
    timeago.setLocaleMessages('tr_short', TrShortMessages());
    _timeagoLocaleRegistered = true;
  }

  @override
  Widget build(BuildContext context) {
    _ensureTimeagoLocaleRegistered();
    final visualConfig = composition.buildVisual(notification);
    final textConfig = composition.buildText(notification);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. GÖRSEL ALANI
            _widgetFactory.buildLeading(notification, visualConfig),

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
                        if (textConfig.title.isNotEmpty)
                          TextSpan(
                            text: '${textConfig.title} ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        // MESAJ (Normal)
                        TextSpan(
                          text: '${textConfig.message} ',
                          style: const TextStyle(fontWeight: FontWeight.w400),
                        ),

                        // AKSİYON METNİ
                        if (textConfig.actionText != null)
                          TextSpan(
                            text: '${textConfig.actionText} ',
                            style: TextStyle(
                              color: textConfig.actionColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        WidgetSpan(
                          child: SizedBox(
                            width: 2.w,
                          ), // İstediğin boşluk miktarını buraya yaz
                        ),
                        // ZAMAN BİLGİSİ
                        TextSpan(
                          text: timeago.format(
                            notification.createdAt,
                            locale: 'tr_short',
                          ),
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 10.sp,
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
