import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/event_status_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/usecases/force_start_event_usecase.dart';
import 'package:outnest/domain/usecases/force_stop_event_usecase.dart';
// Note: You will likely need to import a ForceStopEventUseCase here
// import 'package:outnest/domain/usecases/force_stop_event_usecase.dart';
import 'package:outnest/screens/chat/chat_event_info_chip.dart';
import 'package:outnest/screens/chat/event_avatar_badge.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ChatPageHeader extends StatelessWidget {
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
                        final forceStartEvent = getIt<ForceStartEvent>();
                        forceStartEvent(event);
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
                'Etkinlik durumu "tamamlandı" olarak güncellenecektir.',
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
                      color: Colors.redAccent, // Red to indicate stopping
                      textColor: Colors.white,
                      onTap: () {
                        // TODO: Inject and call ForceStopEvent usecase here
                        final forceStopEvent = getIt<ForceStopEvent>();
                        forceStopEvent(event);
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

  // Helper widget for Dialog Buttons to reduce code duplication
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

  // --- 3. KATILIMCI AYARLARI ---
  void _showParticipantSettingsSheet(BuildContext context) {
    // ... (Existing code remains unchanged)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 24.w,
                height: 3.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              SizedBox(height: 25.h),
              ListTile(
                leading: Icon(
                  Icons.exit_to_app_outlined,
                  color: Colors.black87,
                  size: 24.sp,
                ),
                title: Text(
                  'Buluşmadan Ayrıl',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14.sp,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.error_outline,
                  color: AppColors.primaryColor,
                  size: 24.sp,
                ),
                title: Text(
                  'Şikayet Et',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14.sp,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              SizedBox(height: 35.h),
            ],
          ),
        );
      },
    );
  }

  // --- 4. KONUM DETAY SHEET ---
  void _showLocationDetailSheet(BuildContext context) {
    // ... (Existing code remains unchanged)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12.h),
                Container(
                  width: 24.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(height: 25.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.black87,
                      size: 24.sp,
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14.sp,
                          color: Colors.black87,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    children: [
                      Icon(
                        Icons.map_outlined,
                        color: const Color(0xFF218B3C),
                        size: 24.sp,
                      ),
                      SizedBox(width: 20.w),
                      Text(
                        'Konumu Haritada Gör',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14.sp,
                          color: Colors.green,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 35.h),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isCreator = currentUserId == creatorID;
    final LoggingService logger = getIt<LoggingService>();
    logger.debug('Building ChatPageHeader for eventID: $eventID');

    final topPadding = MediaQuery.of(context).padding.top;

    var participantCount = 0;
    try {
      final parts = participantStatus.split('/');
      participantCount = int.parse(parts[0].trim());
    } catch (_) {}

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
              crossAxisAlignment: CrossAxisAlignment.center,
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
                    imageUrl: creatorProfileImage,
                    categoryIcon: categoryIcon,
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
                              chatTitle,
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
                                // STATUS: UPCOMING -> Show "Force Start" (Play)
                                if (event.status ==
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
                                if (event.status ==
                                    EventStatusEnum.ongoing) ...[
                                  GestureDetector(
                                    onTap: () => _showStopEventDialog(context),
                                    child: _buildCircleActionButton(
                                      icon: Icons.stop_rounded,
                                      color: Colors
                                          .greenAccent, // Distinct color for stop
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                ],

                                // STATUS: COMPLETED -> Render Nothing (Hidden)
                              ],

                              // Settings Button (Always visible)
                              GestureDetector(
                                onTap: () {
                                  if (isCreator) {
                                    final encodedId = Uri.encodeComponent(
                                      eventID,
                                    );

                                    GoRouter.of(context).push(
                                      '/chat/room/$encodedId/settings',
                                      extra: {
                                        'title': chatTitle,
                                        'avatars': participantAvatars,
                                        'location': location,
                                        'participants': participantStatus,
                                        'date': eventDate,
                                        'creatorID': creatorID,
                                        'creatorProfileImage':
                                            creatorProfileImage,
                                      },
                                    );
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

                      // INFO CHIP
                      GestureDetector(
                        onTap: () => _showLocationDetailSheet(context),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: ChatEventInfoChip(
                            location: location,
                            startTime: eventDate,
                            participantCount: participantCount,
                          ),
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
