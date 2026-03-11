import 'package:go_router/go_router.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/presentation/chat/view/components/chat_event_info_chip.dart';
import 'package:outnest/presentation/chat/view/components/event_avatar_badge.dart';
import 'package:outnest/presentation/chat/view/components/event_status_according.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EventChatCard extends StatelessWidget {
  const EventChatCard({
    required this.event,
    required this.isCreator,
    required this.onTapChat,
    this.participantStatus = 'approved',
    super.key,
    this.chatNotificationCount = 0,
    this.pendingRequestCount = 0,
  });

  final EventEntity event;
  final bool isCreator;
  final String participantStatus;
  final int chatNotificationCount;
  final int pendingRequestCount;
  final VoidCallback onTapChat;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(event.eventID)
          .snapshots(),

      builder: (context, snapshot) {
        var displayName = event.name;
        var displayLocation = event.displayAddress.isNotEmpty
            ? event.displayAddress
            : 'Konum Yok';
        var displayDate = event.startTime;

        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {
          final data = snapshot.data!.data()! as Map<String, dynamic>;

          if (data.containsKey('name')) {
            displayName = data['name'] as String;
          }
          if (data.containsKey('displayAddress')) {
            final addr = data['displayAddress'] as String?;
            if (addr != null && addr.isNotEmpty) {
              displayLocation = addr;
            }
          }
          if (data.containsKey('startTime')) {
            final ts = data['startTime'] as Timestamp?;
            if (ts != null) {
              displayDate = ts.toDate();
            }
          }
        }

        final categoryIcon = _getCategoryIcon();

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
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkSlate,
                            ),
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
                    else if (participantStatus == 'pending')
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
      },
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
                Icons.chat_bubble_outline_rounded,
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
          Icons.hourglass_empty_rounded,
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
