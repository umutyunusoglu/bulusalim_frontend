import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/bottomsheetoption.dart';
import 'package:outnest/components/eventcardbackgroundpainter.dart';
import 'package:outnest/components/stacked_avatars.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart'
    show EventRepository;
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/remote_config_service.dart';
import 'package:outnest/domain/services/security_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/screens/home/eventcomponents/event_info_chip.dart';
import 'package:outnest/screens/home/eventcomponents/event_location_chip.dart';
import 'package:outnest/screens/home/eventcomponents/participant_bottom_sheet.dart';

// 3 DURUM
enum _EventJoinStatus {
  canJoin, // 1. Katıl
  pending, // 2. Bekliyor
  joined, // 3. Katıldın
}

//TODO: Participants!

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

  late _EventJoinStatus _joinStatus;

  bool isSaved = false;
  bool isVisible = true;

  @override
  void initState() {
    super.initState();

    logger = getIt<LoggingService>();
    eventRepository = getIt<EventRepository>();
    sessionService = getIt<SessionService>();

    _calculateJoinStatus();
    _checkIfSaved();
  }

  // --- GÜVENLİ DURUM HESAPLAMA ---
  void _calculateJoinStatus() {
    final currentUser = sessionService.currentUser;
    // Kullanıcı yoksa boş string ata, çökmesini engelle
    final uid = currentUser?.userID ?? '';

    // Kullanıcı giriş yapmamışsa varsayılan durum
    if (uid.isEmpty) {
      _joinStatus = _EventJoinStatus.canJoin;
      return;
    }

    // 1. Zaten katılımcı mı? -> KATILDIN
    if (widget.participants.any((p) => p.userID == uid) ||
        widget.event.creator.userID == uid) {
      _joinStatus = _EventJoinStatus.joined;
    }
    // 2. İstek göndermiş mi? -> BEKLİYOR (KUM SAATİ)
    else if (widget.event.requestPool.any((p) => p.userID == uid)) {
      _joinStatus = _EventJoinStatus.pending;
    }
    // 3. Diğer her durumda -> KATIL
    else {
      _joinStatus = _EventJoinStatus.canJoin;
    }
  }

  Future<void> _checkIfSaved() async {
    final currentUser = sessionService.currentUser;
    if (currentUser == null) return; // Güvenlik kontrolü

    if (widget.event.creator.userID == currentUser.userID) {
      if (mounted) setState(() => isSaved = true);
      return;
    }
    final saved = await getIt<UserRepository>().isEventSaved(
      currentUser.userID,
      widget.event.eventID,
    );
    if (mounted) setState(() => isSaved = saved);
  }

  Future<void> _toggleSave() async {
    final currentUser = sessionService.currentUser;
    if (currentUser == null) return; // Güvenlik kontrolü

    final userRepository = getIt<UserRepository>();
    setState(() => isSaved = !isSaved);
    try {
      if (isSaved) {
        await userRepository.saveEvent(currentUser.userID, widget.event);
      } else {
        await userRepository.unSaveEvent(
          currentUser.userID,
          widget.event.eventID,
        );
      }
    } catch (e) {
      logger.error('Error toggling save status: $e');
      if (mounted) setState(() => isSaved = !isSaved);
    }
  }

  // --- ACTION SHEET ---
  void _showActionBottomSheet(bool isEventMine) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CustomActionBottomSheet(
        options: [
          // BULUŞMA SAHİBİ İSE
          if (isEventMine) ...[
            // 1. Buluşma Ayarları
            BottomSheetOption(
              icon: Icons.settings_outlined,
              text: "Buluşma Ayarları'na Git",
              onTap: () {
                sheetContext.pop(); // Önce bottom sheet'i kapatıyoruz

                final encodedId = Uri.encodeComponent(widget.event.id);

                GoRouter.of(context).pushNamed(
                  'eventManagement',
                  pathParameters: {'mgmtID': encodedId},
                  extra: {
                    'title': widget.event.name,
                    'location': widget.event.displayAddress,
                    'avatars': widget.participants,
                    'participants':
                        '${widget.event.participantCount}/${widget.event.capacity}',
                    'remainingTime':
                        'Buluşma Zamanı: ${widget.event.startTime}',
                    'creatorID': widget.event.creator.userID,
                  },
                );
              },
            ),
            // 2. Paylaş
            /* BottomSheetOption(
              icon: Icons.share_outlined,
              text: 'Buluşmayı Paylaş',
              onTap: () {
                logger.info('Buluşma paylaşıldı: ${widget.event.id}');
                sheetContext.pop();
              },
            ),*/
            // 3. Ayrıl
            BottomSheetOption(
              icon: Icons.exit_to_app_outlined,
              text: 'Buluşmadan Ayrıl',
              isDestructive: true,
              onTap: () {
                sheetContext.pop();
                // TODO: Ayrılma servisini çağır
              },
            ),
            // 4. İptal Et
            BottomSheetOption(
              icon: Icons.highlight_off_rounded,
              text: 'Buluşmayı İptal Et',
              isDestructive: true,
              onTap: () async {
                sheetContext.pop();
                // TODO: İptal etme servisini çağır
              },
            ),
          ]
          // BAŞKASININ ETKİNLİĞİ İSE
          else ...[
            // 1. Paylaş
            BottomSheetOption(
              icon: Icons.share_outlined,
              text: 'Buluşmayı Paylaş',
              onTap: () {
                sheetContext.pop();
              },
            ),
            // 2. Engelle
            BottomSheetOption(
              icon: Icons.person_off_outlined,
              text: 'Buluşma Sahibini Engelle',
              isDestructive: true,
              onTap: () async {
                await _handleBlockUser(sheetContext);
              },
            ),
            // 3. Şikayet Et
            BottomSheetOption(
              icon: Icons.error_outline,
              text: 'Şikayet Et',
              isDestructive: true,
              onTap: () async {
                sheetContext.pop();
                await _handleReportEvent(sheetContext);
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleBlockUser(BuildContext sheetContext) async {
    final currentUser = sessionService.currentUser;
    if (currentUser == null) return;

    try {
      await getIt<SecurityService>().blockUser(
        ReportData(
          reportedEntityId: widget.event.id,
          reportedEntityType: 'event',
          reportedUserId: widget.event.creator.userID,
          requestOwnerId: currentUser.userID,
        ),
      );
      if (mounted) setState(() => isVisible = false);
    } catch (e) {
      logger.error('Block user failed: $e');
    }
    if (sheetContext.mounted) sheetContext.pop();
  }

  Future<void> _handleReportEvent(BuildContext sheetContext) async {
    final currentUser = sessionService.currentUser;
    if (currentUser == null) return;

    try {
      await getIt<SecurityService>().sendReport(
        ReportData(
          reportedEntityId: widget.event.id,
          reportedEntityType: 'event',
          reportedUserId: widget.event.creator.userID,
          requestOwnerId: currentUser.userID,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şikayetiniz başarıyla gönderildi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şikayetiniz gönderilirken hata oluştu.'),
          ),
        );
      }
    }
  }

  void _showParticipantsBottomSheet() {
    print('🔥 DEBUG: Bottom sheet açılıyor...'); // Debug için

    final creator = CompactUserEntity(
      userID: widget.event.creator.userID,
      username: widget.event.creator.username,
      profileImageUrl: widget.event.creator.profileImageUrl,
      university: widget.event.creator.university,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return ParticipantsBottomSheet(
          creator: creator,
          participants: widget.participants,
        );
      },
    );
  }

  Future<void> _handleJoinTap() async {
    final currentUser = sessionService.currentUser;
    if (currentUser == null) return; // Güvenlik kontrolü

    if (_joinStatus != _EventJoinStatus.canJoin) return;

    setState(() {
      _joinStatus = _EventJoinStatus.pending;
    });

    try {
      await eventRepository.requestJoin(
        widget.event.id,
        CompactUserEntity(
          userID: currentUser.userID,
          username: currentUser.username,
          profileImageUrl: currentUser.profileImageUrl,
          university: currentUser.university,
        ),
      );

      widget.event.requestPool.add(
        CompactUserEntity(
          userID: currentUser.userID,
          username: currentUser.username,
          profileImageUrl: currentUser.profileImageUrl,
          university: currentUser.university,
        ),
      );
    } catch (e) {
      logger.error('Join request failed: $e');
      if (mounted) {
        setState(() {
          _joinStatus = _EventJoinStatus.canJoin;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İstek gönderilemedi, tekrar deneyin.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = sessionService.currentUser;

    final isEventMine =
        currentUser != null &&
        widget.event.creator.userID == currentUser.userID;

    getIt<RemoteConfigService>();
    final categories = AppConfig.categories;

    final displayAvatars = [
      AvatarInfo(
        userId: widget.event.creator.userID,
        imageUrl: widget.event.creator.profileImageUrl,
      ),
    ];

    if (widget.participants.isNotEmpty) {
      displayAvatars.addAll(
        widget.participants
            .where((user) => user.userID != widget.event.creator.userID)
            .map(
              (user) => AvatarInfo(
                userId: user.userID,
                imageUrl: user.profileImageUrl,
              ),
            ),
      );
    }

    final categoryIcon = widget.event.hobbies.isNotEmpty
        ? categories[widget.event.hobbies[0]] ?? ''
        : '🎉';

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 500),
      crossFadeState: isVisible
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      secondChild: const SizedBox(width: double.infinity),
      firstChild: Padding(
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
              child: SizedBox(
                height: 204.h,
                width: double.infinity,
                child: Stack(
                  children: [
                    // 1. ÜST SATIR
                    Positioned(
                      top: 30.h,
                      left: 0,
                      right: 0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 70.w),
                          SizedBox(
                            width: 221.w,
                            child: Text(
                              widget.event.name.isNotEmpty
                                  ? widget.event.name
                                  : 'İsimsiz Buluşma',
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
                          SizedBox(width: 7.w),

                          // Katılınabilir durumdaysa (canJoin) kaydet butonunu göster
                          if (_joinStatus == _EventJoinStatus.canJoin)
                            SizedBox(
                              width: 24.w,
                              height: 24.w,
                              child: InkWell(
                                onTap: _toggleSave,
                                child: Icon(
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: isSaved
                                      ? AppColors.primaryColor
                                      : Colors.black54,
                                  size: 19.sp,
                                ),
                              ),
                            ),
                          SizedBox(width: 8.w),

                          // 3 NOKTA MENÜ (MORE VERT)
                          SizedBox(
                            width: 19.w,
                            height: 19.w,
                            child: InkWell(
                              onTap: () => _showActionBottomSheet(isEventMine),
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
                            locationName: widget.event.displayAddress,
                          ),
                          SizedBox(height: 4.h),
                          EventInfoChip(
                            startTime: widget.event.startTime,
                            participantCount: widget.event.participantCount,
                            capacity: widget.event.capacity,
                            onParticipantsTap: _showParticipantsBottomSheet,
                          ),
                        ],
                      ),
                    ),

                    // 3. BUTON
                    if (widget.showJoinButton)
                      Positioned(
                        bottom: 12.h,
                        right: 13.w,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _handleJoinTap,
                            borderRadius: BorderRadius.circular(20.r),
                            child: _buildJoinButtonContent(),
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
                    categoryIcon,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 80.h,
              left: 0,
              right: 0,
              child: Center(
                child: StackedAvatars(avatarDataList: displayAvatars),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3 FARKLI BUTON STİLİ
  Widget _buildJoinButtonContent() {
    final width = 72.w;
    final height = 36.h;

    switch (_joinStatus) {
      // 1. KATIL (Standart Dolu Renk)
      case _EventJoinStatus.canJoin:
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
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
            'katıl',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        );

      // 2. BEKLİYOR
      case _EventJoinStatus.pending:
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.hourglass_empty_rounded,
            color: AppColors.primaryColor,
            size: 20.sp,
          ),
        );

      // 3. KATILDIN
      case _EventJoinStatus.joined:
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'katıldın',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        );
    }
  }
}
