import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/stacked_avatars.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

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

  void _onLocationTap() {
    // TODO: Haritada konumu aç
    _logger.debug("Konuma tıklandı");
  }

  void _onManageParticipantsTap() {
    // TODO: Katılımcı yönetimi sayfasına git
    _logger.debug("Katılımcı yönetimine tıklandı");
  }

  void _onReportTap() {
    // TODO: Şikayet dialogunu aç
    _logger.debug("Bildir tıklandı");
  }

  void _onLeaveEventTap() {
    // TODO: Etkinlikten ayrılma servis isteği

    _logger.debug("Etkinlikten ayrıl tıklandı");

    final event = widget.eventID;
    final currentUser = sessionService.currentUser;
    if (currentUser != null) {
      eventRepository.removeParticipant(event, currentUser.userID);
    }

    // go back to messages using go_router
    context.pop();
  }

  void _onCancelEventTap() {
    // TODO: Etkinliği iptal etme servis isteği
    _logger.debug("Etkinliği iptal et tıklandı");
  }

  void _onLockEventChanged(bool value) {
    // TODO: API isteği at
    setState(() {
      isLocked = value;
    });
    debugPrint("Etkinlik kilit durumu: $value");
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = sessionService.currentUser;
    final isCreator =
        currentUser != null && currentUser.userID == widget.creatorID;
    _logger.debug(
      "MyId : ${currentUser?.userID}, CreatorId: ${widget.creatorID}",
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER
            _buildCustomHeader(context),

            // 2. AYARLAR İÇERİĞİ
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Etkinlik Ayarları',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),

                    // Etkinlik Konumu
                    _buildInfoRow(
                      'Etkinlik Konumu',
                      widget.location,
                      icon: Icons.location_on_outlined,
                    ),
                    _buildDivider(),

                    // Etkinlik Zamanı
                    _buildInfoRow(
                      'Etkinlik Zamanı',
                      '15.30 - 18.30',
                      icon: Icons.access_time,
                      isTime: true,
                    ),
                    SizedBox(height: 30.h),

                    // Etkinliği Kilitle
                    if (isCreator)
                      _buildSwitchRow(
                        'Etkinliği Kilitle',
                        'Etkinliğin diğer kullanıcıların karşısına çıkmasını engellersin.',
                        isLocked,
                        (val) => setState(() => isLocked = val),
                      ),
                    if (isCreator) _buildDivider(),

                    // Katılımcı Seçenekleri
                    if (isCreator)
                      _buildActionRow(
                        'Katılımcı Seçenekleri',
                        subtitle:
                            'Etkinliğin hangi kullanıcıların karşısına çıkacağını düzenlersin.',
                        onTap: _onManageParticipantsTap,
                      ),
                    _buildDivider(),

                    // Etkinliği Bildir
                    _buildActionRow('Etkinliği Bildir', onTap: _onReportTap),
                    _buildDivider(),

                    // Etkinlikten Ayrıl
                    if (!isCreator)
                      _buildActionRow(
                        'Etkinlikten Ayrıl',
                        textColor: const Color(0xFFFF5722),
                        onTap: _onLeaveEventTap,
                      ),
                    _buildDivider(),

                    // Etkinliği İptal Et
                    if (isCreator)
                      _buildActionRow(
                        'Etkinliği İptal Et',
                        textColor: const Color(0xFFFF5722),
                        onTap: _onCancelEventTap,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETLAR ---

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(
              Icons.keyboard_backspace,
              color: Colors.blueGrey,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 8.w),

          SizedBox(
            height: 40.h,
            child: StackedAvatars(avatarDataList: widget.participantAvatars),
          ),
          SizedBox(width: 10.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12.sp,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        '${widget.location} • ${widget.participantStatus} • ${widget.remainingTime}',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 11.sp,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // GÜNCELLENDİ: Font özellikleri uygulandı
  Widget _buildInfoRow(
    String title,
    String value, {
    IconData? icon,
    bool isTime = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 16.sp, // 16px
              fontWeight: FontWeight.w500, // Medium (500)
              height: 1, // Line Height %100
              letterSpacing: 0, // Letter Spacing 0
              color: Colors.black87,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isTime ? const Color(0xFFD8EED9) : const Color(0xFFD4E2EB),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                if (icon != null)
                  Icon(icon, size: 16.sp, color: Colors.grey.shade700),
                if (icon != null) SizedBox(width: 6.w),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 13.sp,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // GÜNCELLENDİ: Font özellikleri uygulandı
  Widget _buildSwitchRow(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 16.sp, // 16px
                    fontWeight: FontWeight.w500, // Medium
                    height: 1, // %100
                    letterSpacing: 0,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFFF5722),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    String title, {
    String? subtitle,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 16.sp, // 16px
                // Eğer özel renk (kırmızı) varsa da w500, yoksa da w500
                fontWeight: FontWeight.w500,
                height: 1, // %100
                letterSpacing: 0,
                color: textColor ?? Colors.black87,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey.shade200, thickness: 1);
  }
}
