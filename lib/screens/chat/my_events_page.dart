import 'dart:async';
import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/data/models/user/user_event_model.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/user/user_event_entity.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/domain/repositories/user_repository.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:bulusalim/screens/chat/event_chat_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

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

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  late final String currentUserId;
  late final Stream<List<MyEventItemData>> _enrichedEventsStream;

  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();

    initializeDateFormatting('tr_TR');

    final sessionService = getIt<SessionService>();
    currentUserId = sessionService.currentUser!.userID;
    final eventRepository = getIt<EventRepository>();

    _enrichedEventsStream = eventRepository
        .getEnrichedEventsOfUserStream(currentUserId)
        .asyncMap((events) async {
          return await Future.wait(
            events.map((event) async {
              final pendingCount = event.requestPool.length;
              final unreadCount = 0;

              return MyEventItemData(
                event: event,
                pendingRequestCount: pendingCount,
                unreadChatCount: unreadCount,
              );
            }),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<MyEventItemData>>(
        stream: _enrichedEventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }

          final allEnrichedEvents = snapshot.data ?? [];

          // Filtreleme (Kurucu / Katılımcı)
          final filteredItems = allEnrichedEvents.where((item) {
            final isCreator = item.event.creator.userID == currentUserId;
            return _selectedTabIndex == 0 ? isCreator : !isCreator;
          }).toList();

          // Header'daki Toplam Bildirim Sayısı
          final totalCreatorNotifications = allEnrichedEvents
              .where((item) => item.event.creator.userID == currentUserId)
              .fold(0, (sum, item) => sum + item.pendingRequestCount);

          return SafeArea(
            child: Column(
              children: [
                // 1. HEADER
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
                        creatorNotificationCount: totalCreatorNotifications,
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: Colors.grey.withOpacity(0.2),
                ),

                // 2. İÇERİK LİSTESİ
                Expanded(
                  child: filteredItems.isEmpty
                      ? (_selectedTabIndex == 0
                            ? _buildEmptyCreatorState()
                            : _buildEmptyParticipantState())
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

                            return EventChatCard(
                              event: item.event,
                              isCreator: _selectedTabIndex == 0,
                              pendingRequestCount: item.pendingRequestCount,
                              chatNotificationCount: item.unreadChatCount,

                              onTapChat: () {
                                context.push(
                                  '/chat/room/${item.event.eventID}',
                                  extra: {
                                    'title': item.event.name,
                                    'location':
                                        item.event.displayAddress.isNotEmpty
                                        ? item.event.displayAddress
                                        : 'Konum Yok',
                                    'participants':
                                        '${item.event.participants.length}/${item.event.capacity}',
                                    'time': 'Bugün 21:00', // TODO: Formatla
                                    'creatorID': item.event.creator.userID,
                                    'creatorProfileImage':
                                        item.event.creator.profileImageUrl,
                                    'avatars': item.event.participants,
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
          );
        },
      ),
    );
  }

  // --- WIDGETLAR ---

  Widget _buildCustomToggle({int creatorNotificationCount = 0}) {
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
              notificationCount: creatorNotificationCount,
            ),
          ),
          Expanded(child: _buildToggleItem('katılımcı', 1)),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String text, int index, {int notificationCount = 0}) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        if (_selectedTabIndex != index) {
          setState(() => _selectedTabIndex = index);
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
                  height: 1.0,
                  letterSpacing: 0.0,
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
                    color: AppColors.salmonPink,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lightCloud, width: 1.5),
                  ),
                  child: Text(
                    notificationCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
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

  Widget _buildEmptyCreatorState() {
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
            onTap: () {
              //context.push('/create_event');
            },
            child: Column(
              children: [
                Container(
                  width: 95.w,
                  height: 95.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.salmonPink.withOpacity(0.2),
                    border: Border.all(
                      color: AppColors.salmonPink,
                      width: 2,
                    ),
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

  Widget _buildEmptyParticipantState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Üstteki Açıklama Metni
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 40.w,
            ), // Kenarlardan boşluk
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

          SizedBox(height: 16.h), // Metin ile ikon arası boşluk
          // 2. İkon ve Keşfet Butonu
          GestureDetector(
            onTap: () {
              // Harita veya Keşfet sayfasına yönlendir
              context.go('/map');
            },
            child: Column(
              children: [
                // Harita İkonu
                Icon(
                  Icons.map_outlined,
                  size: 90.sp,
                  color: AppColors.salmonPink.withOpacity(
                    0.3,
                  ),
                ),

                SizedBox(height: 16.h),

                // "Buluşmaları Keşfet" Yazısı
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
