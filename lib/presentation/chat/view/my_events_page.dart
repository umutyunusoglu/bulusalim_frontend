import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_event_providers.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/providers/navbar_badge_provider.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/presentation/chat/view/components/event_chat_card.dart';

@immutable
class MyEventItemData {
  const MyEventItemData({
    required this.event,
    required this.unreadChatCount,
    required this.pendingRequestCount,
  });
  final EventEntity event;
  final int unreadChatCount;
  final int pendingRequestCount;
}

class MyEventsPage extends HookConsumerWidget {
  const MyEventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- HOOKS ---
    useMemoized(() => initializeDateFormatting('tr_TR'));

    // --- PROVIDERS ---
    final currentUserId = ref.watch(currentUserIDProvider);
    final activeEvents = ref.watch(activeEventsProvider);

    // --- VERİ DÖNÜŞÜMÜ ---
    final chatEvents = activeEvents.map((event) {
      return MyEventItemData(
        event: event,
        pendingRequestCount: event.requestPool.length,
        unreadChatCount: 0, // TODO: gerçek unread count
      );
    }).toList();

    // --- BADGE SYNC ---
    final hasUnreadChat = chatEvents.any((item) => item.unreadChatCount > 0);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(navBarBadgeProvider)
            .setBadge(
              tabIndex: 3,
              visible: hasUnreadChat,
            );
      });
      return null;
    }, [hasUnreadChat]);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: EdgeInsets.only(
                left: 24.w,
                right: 24.w,
                top: 24.h,
                bottom: 13.h,
              ),
              child: Row(
                children: [
                  Text(
                    'Buluşmalarım',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                      height: 1,
                      letterSpacing: 0,
                      color: AppColors.darkSlate,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

            // LİSTE VEYA BOŞ DURUM
            Expanded(
              child: chatEvents.isEmpty
                  ? _buildCombinedEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 24.h,
                      ),
                      itemCount: chatEvents.length,
                      separatorBuilder: (c, i) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.dividerColor,
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final item = chatEvents[index];
                        final rawImage = item.event.creator.profileImageUrl;
                        final safeCreatorImage = rawImage.isNotEmpty
                            ? rawImage
                            : FileService.defaultProfileImageUrl();

                        final isCreator =
                            item.event.creator.userID == currentUserId;
                        final isPending = item.event.requestPool.any(
                          (u) => u.userID == currentUserId,
                        );

                        return EventChatCard(
                          event: item.event,
                          isCreator: isCreator,
                          isPending: isPending,
                          pendingRequestCount: item.pendingRequestCount,
                          chatNotificationCount: item.unreadChatCount,
                          onTapChat: () {
                            if (isPending) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Katılım isteğiniz onay bekliyor.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.push(
                              '/chat/room/${item.event.eventID}',
                              extra: {
                                'title': item.event.name,
                                'location': item.event.displayAddress.isNotEmpty
                                    ? item.event.displayAddress
                                    : 'Konum Yok',
                                'participants':
                                    '${item.event.participants.length}/${item.event.capacity}',
                                'startTime': item.event.startTime,
                                'creatorID': item.event.creator.userID,
                                'creatorProfileImage': safeCreatorImage,
                                'avatars': item.event.participants,
                                'event': item.event,
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Text(
          'Şu anda dahil olduğunuz veya kurduğunuz bir buluşma bulunmamaktadır.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textGrey,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
