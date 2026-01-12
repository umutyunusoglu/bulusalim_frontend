import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/stacked_avatars.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/user/compact_user_entity.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:bulusalim/screens/chat/event_avatar_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class EventSettingsPage extends StatefulWidget {
  const EventSettingsPage({
    required this.eventID,
    required this.chatTitle,
    required this.participantAvatars,
    required this.location,
    required this.participantStatus,
    required this.remainingTime,
    required this.creatorID,
    super.key,
  });

  final Identifier eventID;
  final String chatTitle;
  final List<AvatarInfo> participantAvatars;
  final String location;
  final String participantStatus;
  final String remainingTime;
  final String creatorID;

  @override
  State<EventSettingsPage> createState() => _EventSettingsPageState();
}

class _EventSettingsPageState extends State<EventSettingsPage> {
  bool isLocked = false;
  final LoggingService _logger = getIt<LoggingService>();
  final SessionService sessionService = getIt<SessionService>();
  final EventRepository eventRepository = getIt<EventRepository>();

  // --- STYLE CONSTANTS ---
  final TextStyle _labelStyle = TextStyle(
    fontFamily: 'SF Pro Display',
    fontWeight: FontWeight.w500,
    fontSize: 14.sp,
    height: 1.0,
    letterSpacing: 0.0,
    color: Colors.black87,
  );

  final TextStyle _subLabelStyle = TextStyle(
    fontFamily: 'SF Pro Display',
    fontSize: 11.sp,
    color: const Color(0xFF8E8E93),
    height: 1.2,
  );

  // --- ACTIONS ---

  void _onLeaveEventTap() {
    _logger.debug("Etkinlikten ayrıl tıklandı");
    final event = widget.eventID;
    final currentUser = sessionService.currentUser;
    final compactUser = CompactUserEntity(
      userID: currentUser?.userID ?? '',
      username: currentUser?.username ?? '',
      profileImageUrl: currentUser?.profileImageUrl ?? '',
    );
    if (currentUser != null) {
      eventRepository.removeParticipant(event, compactUser);
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = sessionService.currentUser;
    final isCreator =
        currentUser != null && currentUser.userID == widget.creatorID;

    final String profileImage = widget.participantAvatars.isNotEmpty
        ? widget.participantAvatars.first.imageUrl
        : 'https://picsum.photos/200';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            // 1. HEADER
            Padding(
              padding: EdgeInsets.only(
                top: 60.h,
                left: 16.w,
                right: 16.w,
                bottom: 12.h,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                      size: 24.sp,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Buluşma Ayarları',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.w700,
                          fontSize: 16.sp,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 24.sp),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),

                    // 2. PROFİL BÖLÜMÜ (Avatar + Başlık + Edit)
                    Row(
                      children: [
                        // 50x50 Avatar
                        SizedBox(
                          width: 50.w,
                          height: 50.w,
                          child: EventAvatarBadge(
                            imageUrl: profileImage,
                            categoryIcon: '🎉', // Varsayılan ikon
                          ),
                        ),
                        SizedBox(width: 12.w),

                        // Başlık
                        Expanded(
                          child: Text(
                            widget.chatTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        // Edit İkonu (Sadece kurucu ise)
                        if (isCreator)
                          Icon(
                            Icons.edit_outlined,
                            color: Colors.black87,
                            size: 24.sp,
                          ),
                      ],
                    ),

                    SizedBox(height: 40.h),

                    // 3. AYARLAR LİSTESİ

                    // Buluşma Konumu
                    _buildPillRow(
                      'Buluşma Konumu',
                      widget.location.isNotEmpty
                          ? widget.location
                          : 'Konum Seçilmedi',
                      icon: Icons.location_on_outlined,
                    ),
                    _buildDivider(),

                    // Buluşma Zamanı
                    _buildPillRow(
                      'Buluşma Zamanı',
                      '18 Aralık 21.00',
                      icon: Icons.access_time,
                    ),
                    SizedBox(height: 30.h),

                    // Buluşmayı Kilitle
                    if (isCreator) ...[
                      _buildSwitchRow(
                        'Buluşmayı Kilitle',
                        'Buluşman artık kullanıcıların karşısına çıkmaz.',
                        isLocked,
                        (val) => setState(() => isLocked = val),
                      ),
                      _buildDivider(),
                    ],

                    // Görünürlük Seçenekleri
                    if (isCreator) ...[
                      _buildExpandableRow(
                        'Görünürlük Seçenekleri',
                        'Buluşmanın hangi kullanıcıların karşısına çıkacağını düzenlersin.',
                      ),
                      _buildDivider(),
                    ],

                    // Buluşmayı Bildir
                    _buildSimpleActionRow('Buluşmayı Bildir'),
                    _buildDivider(),

                    // Buluşmadan Ayrıl
                    _buildSimpleActionRow(
                      'Buluşmadan Ayrıl',
                      textColor: AppColors.primaryColor,
                      onTap: _onLeaveEventTap,
                    ),

                    // Buluşmayı İptal Et (Sadece Kurucu)
                    if (isCreator) ...[
                      _buildDivider(),
                      _buildSimpleActionRow(
                        'Buluşmayı İptal Et',
                        textColor: AppColors.primaryColor,
                        onTap: () {
                          // İptal fonksiyonu
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  // Konum ve Zaman için Hap (Pill) Görünümlü Satır
  Widget _buildPillRow(String title, String value, {IconData? icon}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: _labelStyle),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFD4E2EB),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14.sp, color: const Color(0xFF4A6572)),
                    SizedBox(width: 4.w),
                  ],
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Switch (Toggle) Satırı
  Widget _buildSwitchRow(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _labelStyle),
                SizedBox(height: 4.h),
                Text(subtitle, style: _subLabelStyle),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: Colors.grey.shade400,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableRow(String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _labelStyle),
                SizedBox(height: 4.h),
                Text(subtitle, style: _subLabelStyle),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: Colors.black87, size: 24.sp),
        ],
      ),
    );
  }

  // Basit Tıklanabilir Satır (Bildir, Ayrıl, İptal Et)
  Widget _buildSimpleActionRow(
    String title, {
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Row(
          children: [
            Text(
              title,
              style: _labelStyle.copyWith(
                color: textColor ?? Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: const Color(0xFFEEEEEE));
  }
}
