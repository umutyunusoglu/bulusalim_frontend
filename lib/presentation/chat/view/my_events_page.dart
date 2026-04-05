import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_event_providers.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
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
    useMemoized(() => initializeDateFormatting('tr_TR'));

    final selectedTab = useState(0);
    final currentUserId = ref.watch(currentUserIDProvider);
    final activeEvents = ref.watch(activeEventsProvider);

    final chatEvents = activeEvents.map((event) {
      return MyEventItemData(
        event: event,
        pendingRequestCount: event.requestPool.length,
        unreadChatCount: 0,
      );
    }).toList();

    final filteredItems = chatEvents.where((item) {
      final isCreator = item.event.creator.userID == currentUserId;
      if (selectedTab.value == 0) {
        return isCreator;
      } else {
        final isParticipant = item.event.participants.any(
          (p) => p.userID == currentUserId,
        );
        final isPending = item.event.requestPool.any(
          (req) => req.userID == currentUserId,
        );
        return !isCreator && (isParticipant || isPending);
      }
    }).toList();

    final totalCreatorNotifications = chatEvents
        .where((item) => item.event.creator.userID == currentUserId)
        .fold(0, (sum, item) => sum + item.pendingRequestCount);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: 24.w,
                right: 24.w,
                top: 24.h,
                bottom: 13.h,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  _buildCustomToggle(
                    selectedTab: selectedTab,
                    creatorNotificationCount: totalCreatorNotifications,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            Expanded(
              child: filteredItems.isEmpty
                  ? (selectedTab.value == 0
                        ? _buildEmptyCreatorState(context)
                        : _buildEmptyParticipantState(context))
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 24.h,
                      ),
                      itemCount: filteredItems.length,
                      separatorBuilder: (c, i) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.dividerColor,
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final rawImage = item.event.creator.profileImageUrl;
                        final safeCreatorImage = rawImage.isNotEmpty
                            ? rawImage
                            : FileService.defaultProfileImageUrl();
                        final isPending = item.event.requestPool.any(
                          (u) => u.userID == currentUserId,
                        );

                        return EventChatCard(
                          event: item.event,
                          isCreator: selectedTab.value == 0,
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

  // --- TOGGLE ---

  Widget _buildCustomToggle({
    required ValueNotifier<int> selectedTab,
    int creatorNotificationCount = 0,
  }) {
    return Container(
      width: 114.w,
      height: 30.h,
      decoration: BoxDecoration(
        color: AppColors.lightCloud,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleItem(
              'kurucu',
              0,
              selectedTab: selectedTab,
              notificationCount: creatorNotificationCount,
            ),
          ),
          Expanded(
            child: _buildToggleItem('katılımcı', 1, selectedTab: selectedTab),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(
    String text,
    int index, {
    required ValueNotifier<int> selectedTab,
    int notificationCount = 0,
  }) {
    final isSelected = selectedTab.value == index;

    return GestureDetector(
      onTap: () {
        if (selectedTab.value != index) {
          selectedTab.value = index;
        }
      },
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 61.w,
              height: 22.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.darkSlate : Colors.transparent,
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                text,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontWeight: FontWeight.w400,
                  fontSize: 12.sp,
                  height: 1,
                  letterSpacing: 0,
                  color: isSelected ? Colors.white : AppColors.darkSlate,
                ),
              ),
            ),
            if (notificationCount > 0)
              Positioned(
                top: -6.h,
                right: -4.w,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lightCloud, width: 1.5),
                  ),
                  child: Text(
                    notificationCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- EMPTY STATES ---

  Widget _buildEmptyCreatorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              'Şu anda kurulu bir buluşmanız bulunmamaktadır.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
                color: AppColors.textGrey,
              ),
            ),
          ),
          SizedBox(height: 20.5.h),
          GestureDetector(
            onTap: () => context.go('/map'),
            child: Column(
              children: [
                Container(
                  width: 95.w,
                  height: 95.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.salmonPink.withOpacity(0.2),
                    border: Border.all(color: AppColors.salmonPink, width: 2),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 60.sp,
                    color: AppColors.salmonPink,
                  ),
                ),
                SizedBox(height: 12.5.h),
                Text(
                  'Buluşma Oluştur',
                  style: TextStyle(
                    fontFamily: 'Sf Pro Display',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.salmonPink,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  Widget _buildEmptyParticipantState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Text(
              'Şu anda katılımcısı olduğunuz veya katılım onayı beklediğiniz bir buluşma bulunmamaktadır.',
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
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Column(
              children: [
                Icon(
                  Symbols.map_search,
                  size: 90.sp,
                  color: AppColors.salmonPink.withOpacity(0.3),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Buluşmaları Keşfet',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.salmonPink,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 60.h),
        ],
      ),
    );
  }
}
