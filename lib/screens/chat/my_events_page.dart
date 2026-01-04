import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/utils/debug/android_image_url_fixer.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/data/models/user/user_event_model.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/user/user_event_entity.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  final String currentUserId = getIt<SessionService>().currentUser!.userID;
  late final Stream<List<UserEventEntity>> _eventsStream;
  bool showApproved = false;
  bool showPending = false;

  //
  @override
  void initState() {
    super.initState();
    final logger = getIt<LoggingService>()
      // 1. ID'yi kontrol et
      ..debug('DEBUG: Sorgu yapılan User ID: $currentUserId');

    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('eventLog')
        .where('status', whereIn: ['upcoming', 'ongoing', 'pending']);

    // 2. Stream'i manuel dinle ve hatayı gör
    _eventsStream = query
        .snapshots()
        .map((snapshot) {
          logger.debug(
            'DEBUG: Snapshot geldi. Doküman sayısı: ${snapshot.docs.length}',
          );

          // Eğer 0 ise filtreleri kaldırıp dene veya koleksiyon adını kontrol et.
          if (snapshot.docs.isEmpty) {
            logger.debug(
              'DEBUG: Veri yok! İndeks eksik olabilir veya status değerleri uyuşmuyor.',
            );
          }

          return snapshot.docs.map((doc) {
            try {
              // Model dönüşümünde hata olup olmadığını kontrol et
              logger.debug('DEBUG: Dönüştürülen data: ${doc.data()}');
              return UserEventModel.fromFirestore(doc.data()).toEntity();
            } catch (e) {
              logger.debug('DEBUG: Model Parse Hatası: $e');
              rethrow;
            }
          }).toList();
        })
        .handleError((Object error) {
          // BURASI ÇOK ÖNEMLİ: İndeks hatası buraya düşer
          logger.debug(
            'DEBUG: Stream Hatası (Muhtemel İndeks Eksikliği): $error',
          );
          return <UserEventEntity>[]; // Hata durumunda boş liste dön
        });
  }

  /// 1. VERİ AKIŞI (STREAM)

  /// 2. SIRALAMA PUANI HESAPLAMA
  int _calculateSortScore(EventEntity event) {
    final participantIds = event.participants.map((p) => p.userID).toList();
    if (event.creator.userID == currentUserId) return 3;

    try {
      final me = event.participants.firstWhereOrNull(
        (p) => p.userID == currentUserId,
      );

      if (me == null) return 0;

      if (participantIds.contains(me.userID)) {
        return 2;
      }

      return 1;
    } on Exception {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Etkinliklerim',
          style: TextStyle(
            color: const Color(0xFFFF5722),
            fontFamily: 'Urbanist',
            fontWeight: FontWeight.w800,
            fontSize: 24.sp,
            fontStyle: FontStyle.italic,
          ),
        ),
        actions: [
          Row(
            children: [
              _buildFilterChip(
                'onaylı',
                const Color(0xFFFF5722),
                showApproved,
                (val) {
                  setState(() => showApproved = val);
                },
              ),
              _buildFilterChip('beklenen', Colors.blueGrey, showPending, (val) {
                setState(() => showPending = val);
              }),
              SizedBox(width: 16.w),
            ],
          ),
        ],
      ),
      // 1. KATMAN: Kullanıcının katıldığı etkinlik ID'lerini dinliyoruz
      body: StreamBuilder<List<UserEventEntity>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userEvents = snapshot.data ?? [];

          // Eğer kullanıcının hiç etkinliği yoksa boşuna DB'ye gitme
          if (userEvents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64.sp,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Henüz bir etkinliğin yok.',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      fontSize: 16.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final eventRepository = getIt<EventRepository>();

          return FutureBuilder<List<EventEntity>>(
            future: eventRepository.getEventsByIds(
              userEvents.map((e) => e.eventId).toList(),
            ),

            builder: (context, eventSnapshot) {
              if (eventSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = eventSnapshot.data ?? [];

              // Filtreleme Mantığı
              final visibleEvents = events.where((event) {
                if (!showApproved && !showPending) return true;

                final score = _calculateSortScore(event);

                // Eğer "Onaylı" seçiliyse, puanı 2 ve 3 olanları göster
                if (showApproved && score >= 2) return true;

                // Eğer "Beklenen" seçiliyse, puanı 1 olanları göster
                if (showPending && score == 1) return true;

                return false;
              }).toList();

              if (visibleEvents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note,
                        size: 64.sp,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Filtreye uygun etkinlik yok.',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 16.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.all(16.w),
                itemCount: visibleEvents.length,
                separatorBuilder: (c, i) =>
                    Divider(color: Colors.grey.shade100, height: 24.h),
                itemBuilder: (context, index) {
                  return _buildEventControlCard(visibleEvents[index]);
                },
              );
            },
          );
        },
      ),
    );
  }

  // --- WIDGETLAR ---

  Widget _buildFilterChip(
    String label,
    Color color,
    bool isActive,
    Function(bool) onTap,
  ) {
    return GestureDetector(
      onTap: () => onTap(!isActive),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 16.w,
              height: 16.w,
              margin: EdgeInsets.only(right: 6.w),
              decoration: BoxDecoration(
                // Seçiliyse renkli, değilse şeffaf
                color: isActive ? color : Colors.transparent,
                border: Border.all(color: color, width: 1.5),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: isActive
                  ? Icon(Icons.check, size: 12.sp, color: Colors.white)
                  : null,
            ),
            Text(
              label,
              style: TextStyle(
                // Yazı rengi her zaman siyah kalsın, okunurluk için
                color: Colors.black87,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Urbanist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventControlCard(EventEntity event) {
    final score = _calculateSortScore(event);
    final isChatEnabled = score >= 2;

    final now = DateTime.now();
    final diff = event.startTime.difference(now);

    String timeText;
    if (diff.isNegative) {
      timeText = 'Başladı';
    } else if (diff.inDays > 0) {
      timeText = '${diff.inDays} gün';
    } else {
      timeText = '${diff.inHours} sa';
    }

    // Statik Konum (Modeline eklediğinde burayı güncelle)
    const locationName = 'Moda, Kadıköy';

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resim
          ClipRRect(
            borderRadius: BorderRadius.circular(50.r),
            child: Image.network(
              (event.creator.profileImageUrl.isNotEmpty)
                  ? fixEmulatorUrl(event.creator.profileImageUrl)
                  : 'https://picsum.photos/200',
              width: 56.w,
              height: 56.w,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 56.w,
                height: 56.w,
                color: Colors.grey.shade200,
                child: const Icon(Icons.person, color: Colors.grey),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Bilgiler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: Colors.black,
                  ),
                ),
                Text(
                  locationName,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 8.h),

                // Hap Bilgiler
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12.sp,
                        color: Colors.black54,
                      ),
                      Text(
                        ' 2.5 km ',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4.w),

                      Icon(
                        Icons.people_outline,
                        size: 12.sp,
                        color: Colors.black54,
                      ),
                      Text(
                        ' ${event.participants.length}/${event.capacity} ',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4.w),

                      Icon(
                        Icons.access_time,
                        size: 12.sp,
                        color: Colors.black54,
                      ),
                      Text(
                        ' $timeText ',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Durum İkonu
          Padding(
            padding: EdgeInsets.only(top: 8.h, left: 8.w),
            child: isChatEnabled
                ? GestureDetector(
                    onTap: () {
                      context.push(
                        '/chat/room/${event.eventID}',
                        extra: {
                          'title': event.name,
                          'image': event.creator.profileImageUrl,
                          'location': locationName,
                          'participants':
                              '${event.participants.length}/${event.capacity}',
                          'time': timeText,
                          'creatorID': event.creator.userID,
                        },
                      );
                    },
                    child: CircleAvatar(
                      radius: 20.r,
                      backgroundColor: const Color(0xFFFF5722),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  )
                : Icon(
                    Icons.hourglass_empty_rounded,
                    color: Colors.blueGrey,
                    size: 28.sp,
                  ),
          ),
        ],
      ),
    );
  }
}
