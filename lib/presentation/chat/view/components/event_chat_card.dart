import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_event_providers.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/presentation/chat/view/components/chat_event_info_chip.dart';
import 'package:outnest/presentation/chat/view/components/event_avatar_badge.dart';
import 'package:outnest/presentation/chat/view/components/event_status_accordion.dart';

class EventChatCard extends ConsumerWidget {
  const EventChatCard({
    required this.event,
    required this.isCreator,
    this.isPending = false,
    required this.onTapChat,
    super.key,
    this.chatNotificationCount = 0,
    this.pendingRequestCount = 0,
  });

  final EventEntity event;
  final bool isCreator;
  final bool isPending;
  final int chatNotificationCount;
  final int pendingRequestCount;
  final VoidCallback onTapChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ongoingEvents = ref.watch(ongoingEventsProvider).value ?? [];
    final displayName = event.name;
    final displayLocation = event.displayAddress.isNotEmpty
        ? event.displayAddress
        : 'Konum Yok';
    final displayDate = event.startTime;
    final categoryIcon = _getCategoryIcon();
    final isOngoing = ongoingEvents.any((e) => e.eventID == event.eventID);

    return Container(
      color: Colors.transparent,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTapChat,
            behavior: HitTestBehavior.translucent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventAvatarBadge(
                  imageUrl: event.creator.profileImageUrl.isNotEmpty
                      ? event.creator.profileImageUrl
                      : FileService.defaultProfileImageUrl(),
                  categoryIcon: categoryIcon,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkSlate,
                              ),
                            ),
                          ),
                          if (isOngoing) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.primaryColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'şu anda',
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'SF Pro Display',
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: ChatEventInfoChip(
                          location: displayLocation,
                          startTime: displayDate,
                          participantCount: event.participants.length,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCreator)
                  _buildChatIcon()
                else if (isPending)
                  _buildPendingIcon()
                else
                  _buildChatIcon(),
              ],
            ),
          ),
          if (isCreator)
            EventStatusAccordion(
              event: event,
              pendingCount: pendingRequestCount,
            ),
        ],
      ),
    );
  }

  Widget _buildChatIcon() {
    return GestureDetector(
      onTap: onTapChat,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
        child: SizedBox(
          width: 30.w,
          height: 30.w,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                Symbols.chat,
                color: AppColors
                    .primaryColor, // Kendi orijinal rengine geri alındı
                size: 22.sp,
              ),
              if (chatNotificationCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: AppColors
                          .salmonPink, // Sadece bildirim balonu salmonPink bırakıldı (orijinal kodundaki gibi)
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      chatNotificationCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        height: 1,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingIcon() {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: SizedBox(
        width: 30.w,
        height: 30.w,
        child: Icon(
          Symbols.hourglass,
          color: AppColors.textGrey.withOpacity(0.5),
          size: 22.sp,
        ),
      ),
    );
  }

  String _getCategoryIcon() {
    if (event.hobbies.isEmpty) return '🎉';
    return AppConfig.categories[event.hobbies.first] ?? '🎉';
  }
}
