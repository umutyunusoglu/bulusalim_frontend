import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/core/utils/types/enums/screen_enum.dart';
import 'package:outnest/core/utils/types/enums/visibility_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart'
    show EventRepository;
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/analytics/event_configs/click_save_event_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/click_view_event_participants_analytics_config.dart';
import 'package:outnest/domain/services/remote_config_service.dart';
import 'package:outnest/domain/services/security_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/services/share_links_service.dart';
import 'package:outnest/presentation/home/view/components/event/event_info_chip.dart';
import 'package:outnest/presentation/home/view/components/event/event_location_chip.dart';
import 'package:outnest/presentation/home/view/components/event/participant_bottom_sheet.dart';
import 'package:outnest/presentation/shared/bottom_sheet_option.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';
import 'package:outnest/presentation/shared/event_card/view/components/event_card_background_painter.dart';
import 'package:outnest/presentation/shared/event_card/view/components/event_join_button.dart';
import 'package:outnest/presentation/shared/event_card/view/components/stacked_avatars.dart';
import 'package:outnest/presentation/shared/popup.dart';
import 'package:outnest/presentation/shared/share_content_bottom_sheet.dart';

class EventCard extends StatefulWidget {
  const EventCard({
    required this.event,
    required this.participants,
    required this.screen,
    this.showJoinButton = true,
    super.key,
  });

  final EventEntity event;
  final ScreenEnum screen;
  final List<CompactUserEntity> participants;
  final bool showJoinButton;

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  late final LoggingService logger;
  late final EventRepository eventRepository;
  late final SessionService sessionService;
  bool _amIFollowingCreator = false;

  bool isSaved = false;
  bool isVisible = true;

  @override
  void initState() {
    super.initState();

    logger = getIt<LoggingService>();
    eventRepository = getIt<EventRepository>();
    sessionService = getIt<SessionService>();
    _updateFollowingStatus();
    sessionService.stateListenable.addListener(_updateFollowingStatus);

    _checkIfSaved();
  }

  @override
  void dispose() {
    sessionService.stateListenable.removeListener(_updateFollowingStatus);
    super.dispose();
  }

  void _updateFollowingStatus() {
    if (!mounted) return;

    final myFollowees = sessionService.stateListenable.value.followees;
    final isFollowing = myFollowees.any(
      (u) => u.userID == widget.event.creator.userID,
    );

    setState(() {
      _amIFollowingCreator = isFollowing;
    });
  }

  Future<void> _checkIfSaved() async {
    final currentUser = sessionService.currentUser;
    if (currentUser == null) return;

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
    if (currentUser == null) return;

    final userRepository = getIt<UserRepository>();
    setState(() => isSaved = !isSaved);
    try {
      getIt<AnalyticsService>().logClickSaveEvent(
        ClickSaveEventAnalyticsConfig(
          eventID: widget.event.eventID,
          value: isSaved,
          screen: widget.screen,
        ),
      );

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

  void _showActionBottomSheet(bool isEventMine) {
    final myEvents = sessionService.activeEvents;
    final myEventIds = myEvents.map((e) => e.eventID);

    final amIaParticipant = myEventIds.contains(widget.event.eventID);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CustomActionBottomSheet(
        options: [
          if (isEventMine) ...[
            BottomSheetOption(
              icon: Icons.settings_outlined,
              text: "Buluşma Ayarları'na Git",
              onTap: () {
                sheetContext.pop();

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
                    'event': widget.event,
                  },
                );
              },
            ),
            if (amIaParticipant)
              BottomSheetOption(
                icon: Symbols.move_item,
                text: 'Buluşmadan Ayrıl',
                isDestructive: true,
                onTap: () {
                  sheetContext.pop();
                  final currentUser = sessionService.currentUser;
                  if (currentUser != null) {
                    final compactUser = CompactUserEntity(
                      userID: currentUser.userID,
                      username: currentUser.username,
                      profileImageUrl: currentUser.profileImageUrl,
                      city: currentUser.city,
                      university: currentUser.university,
                      nameSurname: currentUser.nameSurname,
                      isPrivate: currentUser.isPrivate,
                      bio: currentUser.bio,
                      accountType: currentUser.accountType,
                      communityData: currentUser.communityData,
                    );
                    eventRepository.removeParticipant(
                      widget.event.eventID,
                      compactUser,
                    );
                  }
                },
              ),
            if (amIaParticipant)
              BottomSheetOption(
                icon: Symbols.cancel,
                text: 'Buluşmayı İptal Et',
                isDestructive: true,
                onTap: () async {
                  sheetContext.pop();
                  _onCancelEventTap();
                },
              ),

            if (widget.event.visibility == VisibilityEnum.everyone)
              BottomSheetOption(
                icon: Icons.share,
                text: 'Buluşmayı Paylaş',
                onTap: () {
                  // close only the bottom sheet using the provided sheetContext
                  sheetContext.pop();
                  _handleEventShare();
                },
              ),
          ] else ...[
            if (_amIFollowingCreator)
              BottomSheetOption(
                icon: Icons.person_remove_outlined,
                text: 'Buluşma Sahibini Takibi Bırak',
                onTap: () {
                  sheetContext.pop();
                  _handleUnfollowUser();
                },
              ),
            if (amIaParticipant)
              BottomSheetOption(
                icon: Icons.exit_to_app_outlined,
                text: 'Buluşmadan Ayrıl',
                isDestructive: true,
                onTap: () {
                  sheetContext.pop();
                  final currentUser = sessionService.currentUser;
                  if (currentUser != null) {
                    final compactUser = CompactUserEntity(
                      userID: currentUser.userID,
                      username: currentUser.username,
                      profileImageUrl: currentUser.profileImageUrl,
                      city: currentUser.city,
                      university: currentUser.university,
                      nameSurname: currentUser.nameSurname,
                      isPrivate: currentUser.isPrivate,
                      bio: currentUser.bio,
                      accountType: currentUser.accountType,
                      communityData: currentUser.communityData,
                    );
                    eventRepository.removeParticipant(
                      widget.event.eventID,
                      compactUser,
                    );
                  }
                },
              ),
            BottomSheetOption(
              icon: Icons.person_off_outlined,
              text: 'Buluşma Sahibini Engelle',
              isDestructive: true,
              onTap: () async {
                await _handleBlockUser(sheetContext);
              },
            ),
            BottomSheetOption(
              icon: Icons.error_outline,
              text: 'Şikayet Et',
              isDestructive: true,
              onTap: () async {
                sheetContext.pop();
                await _handleReportEvent(sheetContext);
              },
            ),

            if (widget.event.visibility == VisibilityEnum.everyone)
              BottomSheetOption(
                icon: Icons.share,
                text: 'Buluşmayı Paylaş',
                onTap: () {
                  // close only the bottom sheet using the provided sheetContext
                  sheetContext.pop();
                  _handleEventShare();
                },
              ),
          ],
        ],
      ),
    );
  }

  void _onCancelEventTap() {
    showDialog<void>(
      context: context,
      builder: (context) => Popup(
        title:
            '"${widget.event.name}" buluşmasını iptal etmek istediğinize emin misiniz?',
        description:
            'Buluşmayı iptal etmeniz durumunda katılımcılara bildirim gönderilecektir.',
        confirmButtonText: 'iptal et',
        confirmButtonColor: const Color(0xFF1F415B),
        onConfirm: () async {
          if (mounted) context.pop();
          if (mounted) setState(() => isVisible = false);

          await eventRepository.deleteEvent(widget.event.eventID);
        },
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

  Future<void> _handleUnfollowUser() async {
    try {
      final currentUser = sessionService.currentUser;
      await getIt<UserRepository>().removeFollowee(
        currentUser!.userID,
        widget.event.creator.userID,
      );

      if (mounted) {
        showInfoPopup(context, message: 'Takipten çıkıldı.');
      }
    } catch (e) {
      if (mounted) {
        showErrorPopup(
          context,
          message: 'Takipten çıkma başarısız, lütfen tekrar deneyin.',
        );
      }
    }
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
        showInfoPopup(
          context,
          message: 'Şikayetiniz başarıyla gönderildi ve kullanıcı engellendi',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorPopup(
          context,
          message: 'Şikayetiniz gönderilirken hata oluştu.',
        );
      }
    }
  }

  Future<void> _handleEventShare() async {
    final shareUrl = 'https://outnest.app/share/event/${widget.event.id}';
    try {
      if (!mounted) return;

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => ShareContentBottomSheet(
          title: widget.event.name,
          subtitle: 'Buluşma bağlantısını paylaş',
          avatarImageUrl: widget.event.creator.profileImageUrl,
          shareUrl: shareUrl,
          shareButtonLabel: 'Buluşmayı Paylaş',
          onSharePressed: (bytes) => getIt<ShareLinksService>().shareEvent(
            widget.event.id,
            imageBytes: bytes,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        showErrorPopup(
          context,
          message: 'Paylaşım başarısız oldu, lütfen tekrar deneyin',
        );
      }
    }
  }

  void _showParticipantsBottomSheet() {
    final creator = CompactUserEntity(
      userID: widget.event.creator.userID,
      username: widget.event.creator.username,
      profileImageUrl: widget.event.creator.profileImageUrl,
      city: null,
      university: widget.event.creator.university,
      nameSurname: null,
      isPrivate: null,
      bio: null,
      accountType: null,
      communityData: null,
    );

    getIt<AnalyticsService>().logClickViewEventParticipants(
      ClickViewEventParticipantsAnalyticsConfig(
        eventID: widget.event.eventID,
      ),
    );

    showModalBottomSheet<void>(
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

  @override
  Widget build(BuildContext context) {
    final currentUser = sessionService.currentUser;

    final isEventMine =
        currentUser != null &&
        widget.event.creator.userID == currentUser.userID;

    getIt<RemoteConfigService>();
    final categories = AppConfig.categories;

    final displayAvatars = <AvatarInfo>[];

    if (widget.participants.isNotEmpty) {
      final creatorEntry = widget.participants
          .where((u) => u.userID == widget.event.creator.userID)
          .map((u) => AvatarInfo(userId: u.userID, imageUrl: u.profileImageUrl))
          .firstOrNull;

      if (creatorEntry != null) {
        displayAvatars.add(creatorEntry);
      }

      displayAvatars.addAll(
        widget.participants
            .where((u) => u.userID != widget.event.creator.userID)
            .map(
              (u) => AvatarInfo(userId: u.userID, imageUrl: u.profileImageUrl),
            ),
      );
    }
    final categoryIcon = widget.event.hobbies.isNotEmpty
        ? categories[widget.event.hobbies[0]] ?? ''
        : '🎉';

    final isCommunity = widget.event.accountType == AccountType.community;

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
          bottom: 24.h,
          top: 24.h,
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
                height: 212.h,
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

                    // 3. KATIL BUTONU → EventJoinButton
                    if (widget.showJoinButton)
                      Positioned(
                        bottom: 12.h,
                        right: 12.w,
                        child: isCommunity
                            ? GestureDetector(
                                onTap: () {
                                  context.push(
                                    '/community-event-detail-view',
                                    extra: widget.event,
                                  );
                                },
                                child: Container(
                                  width: 36.w,
                                  height: 36.w,
                                  decoration: const BoxDecoration(
                                    color: AppColors.secondaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x1A000000),
                                        offset: Offset(0, 4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Symbols.info,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                              )
                            : EventJoinButton(
                                event: widget.event,
                                screen: widget.screen,
                              ),
                      ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: -24.h,
              child: isCommunity
                  ? SizedBox(
                      width: 46.w,
                      height: 46.w,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 16.r,
                            backgroundColor: AppColors.inputFillColor,
                            backgroundImage:
                                widget.event.creator.profileImageUrl.isNotEmpty
                                ? NetworkImage(
                                    widget.event.creator.profileImageUrl,
                                  )
                                : null,
                            child: widget.event.creator.profileImageUrl.isEmpty
                                ? Icon(
                                    Icons.group,
                                    size: 16.sp,
                                    color: AppColors.textGrey,
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 18.w,
                              height: 18.h,
                              decoration: BoxDecoration(
                                color: AppColors.cardBackgroundColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.cardBackgroundColor,
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                categoryIcon,
                                style: TextStyle(fontSize: 10.sp),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
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

            // AVATARLAR
            Positioned(
              top: 80.h,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showParticipantsBottomSheet,
                  child: AbsorbPointer(
                    child: StackedAvatars(
                      avatarDataList: displayAvatars,
                    ),
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
