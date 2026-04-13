import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/application/providers/inbox_notification_providers.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/notification/follow_notification_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/domain/services/remote_config_service.dart';
import 'package:url_launcher/url_launcher.dart';

class Header extends ConsumerWidget {
  const Header({
    super.key,
    this.trailing,
    this.middleWidget,
  });

  final Widget? trailing;
  final Widget? middleWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const iconColor = AppColors.secondaryColor;

    return Container(
      color: Colors.transparent,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            // 1. LOGO
            GestureDetector(
              onTap: () async {
                final url = await getIt<RemoteConfigService>().getValue<String>(
                  'outnest_logo_url',
                );
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: SizedBox(
                width: 30.w,
                height: 30.w,
                child: SvgPicture.asset(
                  'assets/outnest/logo.svg',
                ),
              ),
            ),

            // 2. BOŞLUK
            SizedBox(width: 33.w),

            // 3. ORTA WIDGET
            SizedBox(
              width: 236.w,
              height: 45.h,
              child: Center(
                  child: middleWidget ?? const SizedBox(),
              ),
            ),
            // 4. BOŞLUK
            SizedBox(width: 38.w),

            // 5. BİLDİRİM İKONU
            trailing ?? _buildNotificationButton(context, ref, iconColor),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton(
    BuildContext context,
    WidgetRef ref,
    Color iconColor,
  ) {
    final notificationsAsync = ref.watch(notificationStreamProvider);
    final hasUnreadNotifications =
        notificationsAsync.asData?.value.any((n) => !n.isRead) ?? false;
    
    // Watch the notifier state
    final hasUnreadFollowRequests = ref.watch(unreadFollowRequestsProvider);
    
    // When follow requests stream changes, refresh the notifier
    ref.listen<AsyncValue<List<FollowNotificationEntity>>>(
      followRequestsStreamProvider,
      (previous, next) {
        if (next.asData?.value != null) {
          ref.read(unreadFollowRequestsProvider.notifier).refresh();
        }
      },
    );
    
    final showBadge = hasUnreadNotifications || hasUnreadFollowRequests;

    return SizedBox(
      width: 24.sp,
      height: 24.sp,
      child: InkWell(
        onTap: () {
          context.push('/notifications');
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                Icons.notifications_none_outlined,
                color: iconColor,
                size: 24.sp,
              ),
            ),
            if (showBadge)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: AppColors.darkPrimaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
