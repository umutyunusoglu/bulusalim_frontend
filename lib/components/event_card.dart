import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/bottomsheetoption.dart';
import 'package:bulusalim/components/eventcardbackgroundpainter.dart';
import 'package:bulusalim/components/stacked_avatars.dart';
import 'package:bulusalim/core/constants/configs/app_config.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/user/compact_user_entity.dart';
import 'package:bulusalim/screens/home/eventcomponents/event_info_chip.dart';
import 'package:bulusalim/screens/home/eventcomponents/event_location_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class EventCard extends StatefulWidget {
  const EventCard({
    required this.event,
    required this.participants,
    this.showJoinButton = true,
    super.key,
  });

  final EventEntity event;
  final List<CompactUserEntity> participants;
  final bool showJoinButton;

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  late final LoggingService logger;
  late final EventRepository eventRepository;
  late final SessionService sessionService;

  late bool canUserJoin;

  @override
  void initState() {
    super.initState();

    logger = getIt<LoggingService>();
    eventRepository = getIt<EventRepository>();
    sessionService = getIt<SessionService>();

    final currentUser = sessionService.currentUser!;

    canUserJoin = eventRepository.canUserJoinEvent(
      widget.event,
      currentUser.userID,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = sessionService.currentUser!;

    getIt<RemoteConfigService>();
    final categories = AppConfig.categories;

    final displayAvatars = widget.participants.isNotEmpty
        ? widget.participants
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
          CustomPaint(
            painter: EventCardBackgroundPainter(
              backgroundColor: AppColors.cardBackgroundColor,
              bumpRadius: 25.w,
              bumpOffset: 24.h,
            ),
            child: Container(
              height: 204.h,
              width: double.infinity,
              child: Stack(
                children: [
                  // 1. ÜST SATIR (BAŞLIK + İKONLAR)
                  Positioned(
                    top: 30.h,
                    left: 0,
                    right: 0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 70.w), // Soldan boşluk
                        // Başlık
                        SizedBox(
                          width: 221.w,
                          child: Text(
                            widget.event.name.isNotEmpty
                                ? widget.event.name
                                : 'Bizimle beraber tracking yapmak ister misiniz???',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16.sp,
                              height: 1.1,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        SizedBox(width: 7.w),

                        // Kaydet İkonu
                        SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: InkWell(
                            onTap: () {},
                            child: Icon(
                              Icons.bookmark_border,
                              color: Colors.black54,
                              size: 19.sp,
                            ),
                          ),
                        ),

                        SizedBox(width: 8.w),

                        // Ayarlar İkonu
                        SizedBox(
                          width: 19.w,
                          height: 19.w,
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet<void>(
                                context: context,
                                useRootNavigator: true,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => CustomActionBottomSheet(
                                  height: 201.h,
                                  options: [
                                    BottomSheetOption(
                                      icon: Icons.person_off_outlined,
                                      text: 'Buluşma Sahibini Takibi Bırak',
                                      onTap: () {
                                        logger.info('Takip bırakıldı');
                                        context.pop();
                                      },
                                    ),
                                    BottomSheetOption(
                                      icon: Icons.share_outlined,
                                      text: 'Paylaş',
                                      onTap: () {
                                        logger.info('Paylaşıldı');
                                        context.pop();
                                      },
                                    ),
                                    BottomSheetOption(
                                      icon: Icons.report_gmailerrorred_outlined,
                                      text: 'Şikayet Et',
                                      isDestructive: true,
                                      onTap: () {
                                        logger.info('Şikayet edildi');
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
                        SizedBox(width: 12.w),
                      ],
                    ),
                  ),

                  // 2. SOL ALT (CHIPS)
                  Positioned(
                    bottom: 12.h,
                    left: 12.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EventLocationChip(
                          locationName: widget.event.address,
                        ),
                        SizedBox(height: 4.h),
                        EventInfoChip(
                          startTime: widget.event.startTime,
                          participantCount: widget.event.participantCount,
                          capacity: widget.event.capacity,
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: 12.h,
                    right: 13.w,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: !canUserJoin
                            ? null
                            : () async {
                                await eventRepository.requestJoin(
                                  widget.event.id,
                                  CompactUserEntity(
                                    userID: currentUser.userID,
                                    username: currentUser.username,
                                    profileImageUrl:
                                        currentUser.profileImageUrl,
                                  ),
                                );

                                setState(() {
                                  canUserJoin = false;

                                  widget.event.requestPool.add(
                                    CompactUserEntity(
                                      userID: currentUser.userID,
                                      username: currentUser.username,
                                      profileImageUrl:
                                          currentUser.profileImageUrl,
                                    ),
                                  );
                                });
                              },
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          width: 72.w,
                          height: 36.h,
                          decoration: BoxDecoration(
                            color: canUserJoin
                                ? AppColors.primaryColor
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26000000),
                                offset: Offset(0, 4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            canUserJoin ? 'katıl' : 'kilitli',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Positioned(
            top: -24.h,
            child: SizedBox(
              width: 50.w,
              height: 50.w,
              child: Center(
                child: Text(
                  categories[widget.event.hobbies[0]] ?? '',
                ),
              ),
            ),
          ),

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
}
