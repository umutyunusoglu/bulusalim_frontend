import 'package:intl/intl.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/domain/services/security_service.dart';
import 'package:outnest/presentation/shared/bottom_sheet_option.dart';
import 'package:outnest/presentation/shared/popup.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/event_status_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/usecases/force_start_event_usecase.dart';
import 'package:outnest/domain/usecases/force_stop_event_usecase.dart';
import 'package:outnest/presentation/chat/view/components/chat_event_info_chip.dart';
import 'package:outnest/presentation/chat/view/components/event_avatar_badge.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/presentation/home/view/components/event/participant_bottom_sheet.dart';

class ChatPageHeader extends StatefulWidget {
  const ChatPageHeader({
    required this.eventID,
    required this.event,
    required this.creatorID,
    required this.chatTitle,
    required this.creatorProfileImage,
    required this.location,
    required this.eventDate,
    required this.participantStatus,
    required this.participantAvatars,
    this.categoryIcon = '🎉',
    super.key,
  });

  final String eventID;
  final EventEntity event;
  final String creatorID;
  final String chatTitle;
  final String creatorProfileImage;
  final String location;
  final DateTime eventDate;
  final String participantStatus;
  final List<dynamic> participantAvatars;
  final String categoryIcon;

  @override
  State<ChatPageHeader> createState() => _ChatPageHeaderState();
}

class _ChatPageHeaderState extends State<ChatPageHeader> {
  // Optimistic Update için lokal state
  late EventStatusEnum _currentStatus;
  late EventEntity _event;
  late String _chatTitle;
  late String _location;
  late DateTime _eventDate;

  @override
  void initState() {
    super.initState();
    // Başlangıçta gelen event status'u alıyoruz
    _currentStatus = widget.event.status;
    _event = widget.event;
    _chatTitle = widget.chatTitle;
    _location = widget.location;
    _eventDate = widget.eventDate;
  }

  @override
  void didUpdateWidget(covariant ChatPageHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Eğer parent widget'tan yeni bir status gelirse (server sync)
    // lokal state'i güncelliyoruz.
    if (widget.event.status != oldWidget.event.status) {
      setState(() {
        _currentStatus = widget.event.status;
      });
    }
    if (widget.event != oldWidget.event) {
      setState(() {
        _event = widget.event;
      });
    }
    if (widget.chatTitle != oldWidget.chatTitle) {
      setState(() => _chatTitle = widget.chatTitle);
    }
    if (widget.location != oldWidget.location) {
      setState(() => _location = widget.location);
    }
    if (widget.eventDate != oldWidget.eventDate) {
      setState(() => _eventDate = widget.eventDate);
    }
  }

  Future<void> _refreshEventData() async {
    try {
      final updatedEvent = await getIt<EventRepository>().getEvent(
        widget.eventID,
      );
      if (updatedEvent != null && mounted) {
        setState(() {
          _event = updatedEvent;
          _currentStatus = updatedEvent.status;
          _chatTitle = updatedEvent.name;
          _location = updatedEvent.displayAddress;
          _eventDate = updatedEvent.startTime;
        });
      }
    } catch (e) {
      getIt<LoggingService>().error('Event refresh failed: $e');
    }
  }

  // --- 1. START POPUP (FORCE START) ---
  void _showStartEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 36.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Buluşmayı ayarlanan zamandan önce başlatmak istediğinize emin misiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Katılımcılara buluşmayı başlattığınıza dair bildirim gönderilecektir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 10.sp,
                  color: Colors.grey.shade400,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: _buildDialogButton(
                      context,
                      label: 'vazgeç',
                      color: const Color(0xFFF3F4F6),
                      textColor: Colors.black87,
                      onTap: () => context.pop(),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildDialogButton(
                      context,
                      label: 'başlat',
                      color: AppColors.primaryColor,
                      textColor: Colors.white,
                      onTap: () {
                        // 1. Önce UI'ı güncelle (Optimistic Update)
                        setState(() {
                          _currentStatus = EventStatusEnum.ongoing;
                        });

                        // 2. Sonra isteği at
                        final forceStartEvent = getIt<ForceStartEvent>();
                        forceStartEvent(_event);

                        // 3. Dialog'u kapat
                        context.pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. STOP POPUP (FORCE STOP) ---
  void _showStopEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 36.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Buluşmayı sonlandırmak istediğinize emin misiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Buluşma durumu "tamamlandı" olarak güncellenecektir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 10.sp,
                  color: Colors.grey.shade400,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: _buildDialogButton(
                      context,
                      label: 'vazgeç',
                      color: const Color(0xFFF3F4F6),
                      textColor: Colors.black87,
                      onTap: () => context.pop(),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildDialogButton(
                      context,
                      label: 'bitir',
                      color: Colors.redAccent,
                      textColor: Colors.white,
                      onTap: () {
                        // 1. Önce UI'ı güncelle (Optimistic Update)
                        setState(() {
                          _currentStatus = EventStatusEnum.completed;
                        });

                        // 2. Sonra isteği at
                        final forceStopEvent = getIt<ForceStopEvent>();
                        forceStopEvent(_event);

                        // 3. Dialog'u kapat
                        context.pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for Dialog Buttons
  Widget _buildDialogButton(
    BuildContext context, {
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  // 3. KATILIMCI AYARLARI
  void _showParticipantSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return CustomActionBottomSheet(
          options: [
            BottomSheetOption(
              icon: Icons.exit_to_app_rounded,
              text: 'Buluşmadan Ayrıl',
              onTap: () {
                Navigator.pop(context);
                _showLeaveEventDialog(context);
              },
            ),
            BottomSheetOption(
              icon: Icons.report_problem_outlined,
              text: 'Şikayet Et',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                getIt<SecurityService>().sendReport(
                  ReportData(
                    reportedEntityId: _event.eventID,
                    reportedEntityType: "event",
                    reportedUserId: _event.creator.userID,
                    requestOwnerId: getIt<SessionService>().currentUser!.userID,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showLeaveEventDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Popup(
        title:
            '"$_chatTitle" buluşmasından ayrılmak istediğinize emin misiniz?',
        description:
            'Ayrıldığınızda bu sohbetten ve buluşma listesinden çıkarılacaksınız.',
        confirmButtonText: 'ayrıl',
        confirmButtonColor: const Color(0xFF1F415B),
        onConfirm: () {
          final sessionService = getIt<SessionService>();
          final eventRepository = getIt<EventRepository>();
          final currentUser = sessionService.currentUser;
          if (currentUser != null) {
            final compactUser = CompactUserEntity(
              userID: currentUser.userID,
              username: currentUser.username,
              profileImageUrl: currentUser.profileImageUrl,
              university: currentUser.university,
              nameSurname: currentUser.nameSurname,
              isPrivate: currentUser.isPrivate,
              bio: currentUser.bio,
              accountType: currentUser.accountType,
              communityData: currentUser.communityData,
            );
            eventRepository.removeParticipant(widget.eventID, compactUser);
          }

          context.pop();
        },
      ),
    );
  }

  void _showLocationDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return CustomActionBottomSheet(
          options: [
            BottomSheetOption(
              icon: Icons.location_on_outlined,
              text: _location,
              onTap:
                  () {}, // Sadece bilgi amaçlı olduğu için boş bırakabilirsin
            ),
            BottomSheetOption(
              icon: Icons.map_outlined,
              text: 'Konumu Haritada Gör',
              onTap: () {
                // TODO: Harita açma logic'i
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // --- ZAMAN DETAY POPUP ---
  void _showTimeDetailSheet(BuildContext context) {
    final eventTimeText = DateFormat(
      'dd MMMM HH.mm',
      'tr_TR',
    ).format(_eventDate);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return CustomActionBottomSheet(
          options: [
            BottomSheetOption(
              icon: Icons.access_time_rounded,
              text:
                  'Buluşma $eventTimeText tarihinde başlayacak şekilde planlandı.',
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  // --- KATILIMCI LİSTESİ POPUP ---
  void _showParticipantsBottomSheet() {
    final creatorEntity = CompactUserEntity(
      userID: widget.creatorID,
      username: _event.creator.username,
      profileImageUrl: widget.creatorProfileImage,
      university: _event.creator.university,
      nameSurname: null,
      isPrivate: null,
      bio: null,
      accountType: null,
      communityData: null,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return ParticipantsBottomSheet(
          creator: creatorEntity,
          participants: _event.participants,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isCreator = currentUserId == widget.creatorID;
    final logger = getIt<LoggingService>()
      ..debug('Building ChatPageHeader for eventID: ${widget.eventID}');

    final topPadding = MediaQuery.of(context).padding.top;

    final participantCount = _event.participantCount;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.only(top: topPadding + 5.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                // 1. Geri Butonu
                InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: Icon(
                      Icons.arrow_back,
                      size: 24.sp,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),

                // 2. Avatar
                SizedBox(
                  width: 50.w,
                  height: 50.w,
                  child: EventAvatarBadge(
                    imageUrl: widget.creatorProfileImage,
                    categoryIcon: widget.categoryIcon,
                  ),
                ),
                SizedBox(width: 12.w),

                // 3. İçerik ve Aksiyon Butonları
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Üst Satır
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _chatTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontWeight: FontWeight.w500,
                                fontSize: 14.sp,
                                color: Colors.black,
                                height: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),

                          // --- ACTION BUTTON LOGIC START ---
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Only render action buttons if user is creator
                              if (isCreator) ...[
                                // Local state (_currentStatus) kullanıyoruz

                                // STATUS: UPCOMING -> Show "Force Start" (Play)
                                if (_currentStatus ==
                                    EventStatusEnum.upcoming) ...[
                                  GestureDetector(
                                    onTap: () => _showStartEventDialog(context),
                                    child: _buildCircleActionButton(
                                      icon: Icons.play_arrow,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                ],

                                // STATUS: ONGOING -> Show "Force Stop" (Stop)
                                if (_currentStatus ==
                                    EventStatusEnum.ongoing) ...[
                                  GestureDetector(
                                    onTap: () => _showStopEventDialog(context),
                                    child: _buildCircleActionButton(
                                      icon: Icons.stop_rounded,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                ],

                                // STATUS: COMPLETED -> Render Nothing (Hidden)
                              ],

                              // Settings Button (Always visible)
                              GestureDetector(
                                onTap: () async {
                                  if (isCreator) {
                                    final encodedId = Uri.encodeComponent(
                                      widget.eventID,
                                    );

                                    await GoRouter.of(context).push(
                                      '/chat/room/$encodedId/settings',
                                      extra: {
                                        'title': _chatTitle,
                                        'avatars': widget.participantAvatars,
                                        'location': _location,
                                        'participants':
                                            widget.participantStatus,
                                        'startTime': _eventDate,
                                        'creatorID': widget.creatorID,
                                        'creatorProfileImage':
                                            widget.creatorProfileImage,
                                        'event': _event,
                                      },
                                    );
                                    // Settings sayfasından dönünce verileri güncelle
                                    await _refreshEventData();
                                  } else {
                                    _showParticipantSettingsSheet(context);
                                  }
                                },
                                child: Icon(
                                  Icons.settings_outlined,
                                  size: 24.sp,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          // --- ACTION BUTTON LOGIC END ---
                        ],
                      ),
                      SizedBox(height: 4.h),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: ChatEventInfoChip(
                          location: _location,
                          startTime: _eventDate,
                          participantCount: participantCount,
                          // Sadece konum kısmına tıklandığında tetiklenecek:
                          onLocationTap: () =>
                              _showLocationDetailSheet(context),
                          onTimeTap: () => _showTimeDetailSheet(context),
                          onParticipantsTap: () =>
                              _showParticipantsBottomSheet(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
        ],
      ),
    );
  }

  // Helper for the circular action button
  Widget _buildCircleActionButton({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 16.sp,
      ),
    );
  }
}
