import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/bottomsheetoption.dart';
import 'package:bulusalim/components/eventcardbackgroundpainter.dart';
import 'package:bulusalim/components/stacked_avatars.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/screens/home/eventcomponents/event_info_chip.dart';
import 'package:bulusalim/screens/home/eventcomponents/event_location_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    required this.event,
    required this.participants,
    super.key,
  });

  final EventEntity event;
  final List<EventParticipantEntity> participants;

  @override
  Widget build(BuildContext context) {
    final _logger = getIt<LoggingService>();

    // --- Veri Hazırlığı ---
    final displayAvatars = participants.isNotEmpty
        ? participants
              .map(
                (user) => AvatarInfo(
                  userId: user.userID,
                  imageUrl: user.profileImageUrl,
                ),
              )
              .toList()
        : <AvatarInfo>[
            AvatarInfo(
              userId: '1',
              imageUrl: 'https://picsum.photos/seed/1/100',
            ),
            AvatarInfo(
              userId: '2',
              imageUrl: 'https://picsum.photos/seed/2/100',
            ),
            AvatarInfo(
              userId: '3',
              imageUrl: 'https://picsum.photos/seed/3/100',
            ),
          ];

    const staticLocationName = 'İnegöl, Bolu';

    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        bottom: 12.h,
        top: 25.h,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // --- KART GÖVDESİ + PAINTER (GÖLGE DAHİL) ---
          CustomPaint(
            painter: EventCardBackgroundPainter(
              backgroundColor: AppColors.cardBackgroundColor,
              bumpRadius: 25.w,
              bumpOffset: 24.h,
            ),
            child: Container(
              height: 204.h,
              width: double.infinity,
              padding: EdgeInsets.zero,
              child: Stack(
                children: [
                  // 1. ÜST SATIR (BAŞLIK + İKONLAR) - TEK ROW
                  Positioned(
                    top: 30.h,
                    left: 0,
                    right: 0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. SOLDAN 70 BOŞLUK
                        SizedBox(width: 70.w),

                        // 2. YAZI (221px)
                        SizedBox(
                          width: 221.w,
                          child: Text(
                            event.name.isNotEmpty
                                ? event.name
                                : "Bizimle beraber tracking yapmak ister misiniz???",
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontWeight: FontWeight.w500,
                              fontSize: 16.sp,
                              height: 1.1,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        // 3. YAZI SONRASI 7 BOŞLUK
                        SizedBox(width: 7.w),

                        // 4. KAYDET İKONU (24px)
                        SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: InkWell(
                            onTap: () {},
                            child: Icon(
                              Icons.bookmark_border,
                              color: Colors.black54,
                              size: 19.sp, // İstenilen Boyut
                            ),
                          ),
                        ),

                        // 5. İKONLAR ARASI 8 BOŞLUK
                        SizedBox(width: 8.w),

                        // 6. AYARLAR İKONU
                        SizedBox(
                          width: 19.w,
                          height: 19.w,
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                useRootNavigator: true,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => CustomActionBottomSheet(
                                  height: 201.h,
                                  options: [
                                    BottomSheetOption(
                                      icon: Icons.person_off_outlined,
                                      text: "Buluşma Sahibini Takibi Bırak",
                                      onTap: () {
                                        _logger.info("Takip bırakıldı");
                                        context.pop();
                                      },
                                    ),
                                    BottomSheetOption(
                                      icon: Icons.share_outlined,
                                      text: "Paylaş",
                                      onTap: () {
                                        _logger.info("Paylaşıldı");
                                        context.pop();
                                      },
                                    ),
                                    BottomSheetOption(
                                      icon: Icons.report_gmailerrorred_outlined,
                                      text: "Şikayet Et",
                                      isDestructive: true, // KIRMIZI YAPAR
                                      onTap: () {
                                        _logger.info("Şikayet edildi");
                                        context.pop();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Icon(
                              Icons.more_vert,
                              color: Colors.black54,
                              size: 19.sp,
                            ),
                          ),
                        ),

                        // 7. EN SAĞDAKİ 12 BOŞLUK
                        SizedBox(width: 12.w),
                      ],
                    ),
                  ),

                  // 2. Sol Alt Kısım (CHIPS)
                  Positioned(
                    bottom: 12.h,
                    left: 12.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LOKASYON ÇİPİ
                        const EventLocationChip(
                          locationName: 'İnegöl, Bolu',
                        ),

                        SizedBox(height: 4.h),

                        // INFO ÇİPİ
                        EventInfoChip(
                          startTime: event.startTime,
                          participantCount: event.participants.length,
                          capacity: event.capacity,
                        ),
                      ],
                    ),
                  ),

                  // 3. SAĞ ALT (KATIL BUTONU)
                  Positioned(
                    bottom: 12.h,
                    right: 13.w,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _logger.info("Katıl: ${event.id}");
                        },
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          width: 72.w,
                          height: 36.h,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(20.r),
                            // BUTON GÖLGESİ
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26000000),
                                offset: Offset(0, 4),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "katıl",
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- YÜZEN IKON ---
          Positioned(
            top: -24.h,
            child: SizedBox(
              width: 50.w,
              height: 50.w,
              child: Center(
                child: Image.network(
                  "https://cdn-icons-png.flaticon.com/512/2553/2553644.png",
                  width: 24.w,
                  height: 24.w,
                  errorBuilder: (c, e, s) =>
                      Icon(Icons.hiking, color: Colors.brown, size: 24.sp),
                ),
              ),
            ),
          ),

          // --- AVATAR GRUBU ---
          Positioned(
            top: 80.h,
            left: 0,
            right: 0,
            child: Center(
              child: StackedAvatars(
                avatarDataList: displayAvatars,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventDate(DateTime date) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cuma', 'Cmt', 'Paz'];
    final weekDayName = days[date.weekday - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$weekDayName $hour.$minute";
  }
}
