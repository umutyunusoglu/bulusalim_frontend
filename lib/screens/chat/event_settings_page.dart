import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/popup.dart';
import 'package:outnest/components/stacked_avatars.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/screens/chat/event_avatar_badge.dart';

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

  late String _currentLocation;
  DateTime? _currentDate;
  String _categoryIcon = '🎉'; // varsayılan ikon

  final LoggingService _logger = getIt<LoggingService>();
  final SessionService sessionService = getIt<SessionService>();
  final EventRepository eventRepository = getIt<EventRepository>();

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.location;
    _fetchCurrentEventData();
  }

  Future<void> _fetchCurrentEventData() async {
    try {
      final data = await eventRepository.getEvent(widget.eventID);

      if (data != null && mounted) {
        setState(() {
          _currentDate = data.startTime;

          if (data.hobbies.isNotEmpty) {
            final hobbies = data.hobbies;
            if (hobbies.isNotEmpty) {
              final category = hobbies.first;
              _categoryIcon = AppConfig.categories[category] ?? '🎉';
            }
          }
        });
      }
    } catch (e) {
      _logger.error('Veri çekme hatası: $e');
    }
  }

  Future<void> _onLocationUpdateTap() async {
    final result = await context.push<Map<String, dynamic>>(
      '/pick-location-map',
    );

    if (result != null) {
      _logger.debug('Yeni konum seçildi: $result');
      final newDisplayAddress = result['displayAddress'] as String;
      final newAddress = result['address'] as String;
      final newLocation = result['location'] as GeoPoint;

      if (!mounted) return;
      setState(() {
        _currentLocation = newDisplayAddress;
      });

      try {
        await eventRepository.updateEvent(
          widget.eventID,
          {
            'displayAddress': newDisplayAddress,
            'address': newAddress,
            'location': GeoPoint(
              (newLocation.latitude as num).toDouble(),
              (newLocation.longitude as num).toDouble(),
            ),
            'geohash': GeoHasher().encode(
              (newLocation.longitude as num).toDouble(),
              (newLocation.latitude as num).toDouble(),
              precision: 7,
            ),
          },
        );
        _logger.debug('Konum güncellendi: $newDisplayAddress');
      } catch (e) {
        _logger.error('Konum güncelleme hatası: $e');
        if (mounted) {
          setState(() {
            _currentLocation = widget.location;
          });
        }
      }
    }
  }

  Future<void> _onTimeUpdateTap() async {
    final result = await context.push<Map<String, dynamic>>(
      '/pick-time-map',
    );

    if (result != null) {
      final newDate = result['date'] as DateTime;
      final newTime = result['time'] as TimeOfDay?;

      final newStartTime = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        newTime?.hour ?? 0,
        newTime?.minute ?? 0,
      );

      if (!mounted) return;
      setState(() {
        _currentDate = newStartTime;
      });

      try {
        await eventRepository.updateEvent(
          widget.eventID,
          {
            'startTime': newStartTime,
            'endTime': newStartTime.add(const Duration(hours: 2)),
          },
        );
        _logger.debug('Zaman güncellendi: $newStartTime');
      } catch (e) {
        _logger.error('Zaman güncelleme hatası: $e');
      }
    }
  }

  void _onLeaveEventTap() {
    showDialog<void>(
      context: context,
      builder: (context) => Popup(
        title:
            '"${widget.chatTitle}" buluşmasından ayrılmak istediğinize emin misiniz?',
        description:
            'Kurucusu olduğunuz buluşmadan ayrılmanız durumunda katılımcılardan biri yeni kurucu olarak atanacaktır.',
        confirmButtonText: 'ayrıl',
        confirmButtonColor: const Color(0xFF1F415B),
        onConfirm: () {
          _performLeaveLogic();
        },
      ),
    );
  }

  void _performLeaveLogic() {
    final currentUser = sessionService.currentUser;
    if (currentUser != null) {
      final compactUser = CompactUserEntity(
        userID: currentUser.userID,
        username: currentUser.username,
        profileImageUrl: currentUser.profileImageUrl,
        university: currentUser.university,
      );
      eventRepository.removeParticipant(widget.eventID, compactUser);
    }
    context.pop();
    context.pop();
  }

  void _onCancelEventTap() {
    showDialog<void>(
      context: context,
      builder: (context) => Popup(
        title:
            '"${widget.chatTitle}" buluşmasını iptal etmek istediğinize emin misiniz?',
        description:
            'Buluşmayı iptal etmeniz durumunda katılımcılara bildirim gönderilecektir.',
        confirmButtonText: 'iptal et',
        confirmButtonColor: const Color(0xFF1F415B),
        onConfirm: () async {
          if (mounted) context.pop();

          await eventRepository.deleteEvent(widget.eventID);
        },
      ),
    );
  }

  // Styles
  TextStyle get _labelStyle => TextStyle(
    fontFamily: 'SF Pro Display',
    fontWeight: FontWeight.w600,
    fontSize: 14.sp,
    height: 1.0,
    color: Colors.black87,
  );

  TextStyle get _subLabelStyle => TextStyle(
    fontFamily: 'SF Pro Display',
    fontSize: 12.sp,
    color: const Color(0xFF8E8E93),
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    final currentUser = sessionService.currentUser;
    final isCreator =
        currentUser != null && currentUser.userID == widget.creatorID;

    final String profileImage = widget.participantAvatars.isNotEmpty
        ? widget.participantAvatars.first.imageUrl
        : 'https://picsum.photos/200';

    String dateString = 'Yükleniyor...';
    if (_currentDate != null) {
      dateString = DateFormat('d MMMM HH.mm', 'tr_TR').format(_currentDate!);
    } else {
      // Eğer widget.remainingTime varsa onu kullan
      dateString = widget.remainingTime.isNotEmpty
          ? widget.remainingTime
          : dateString;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F6),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
            child: Column(
              children: [
                // HEADER ROW (back + title centered)
                Row(
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
                    SizedBox(
                      width: 24.sp,
                    ), // placeholder to keep title centered
                  ],
                ),

                SizedBox(height: 18.h),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PROFILE ROW
                    Row(
                      children: [
                        // Avatar with small badge
                        SizedBox(
                          width: 56.w,
                          height: 56.w,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 28.w,
                                backgroundImage: NetworkImage(profileImage),
                              ),
                              Positioned(
                                bottom: -2.h,
                                right: -2.w,
                                child: Container(
                                  width: 26.w,
                                  height: 26.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _categoryIcon,
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            widget.chatTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontWeight: FontWeight.w600,
                              fontSize: 15.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (isCreator)
                          Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: InkWell(
                              onTap: () {
                                // edit action
                              },
                              borderRadius: BorderRadius.circular(8.r),
                              child: Container(
                                padding: EdgeInsets.all(6.w),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 20.sp,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 22.h),

                    // Location row
                    _buildPillRow(
                      title: 'Buluşma Konumu',
                      value: _currentLocation.isNotEmpty
                          ? _currentLocation
                          : 'Konum seçilmedi',
                      icon: Icons.location_on_outlined,
                      onTap: isCreator ? _onLocationUpdateTap : null,
                    ),
                    _thinDivider(),

                    // Time row
                    _buildPillRow(
                      title: 'Buluşma Zamanı',
                      value: dateString,
                      icon: Icons.access_time,
                      onTap: isCreator ? _onTimeUpdateTap : null,
                      showTrailing: true,
                    ),

                    SizedBox(height: 8.h),

                    if (isCreator) ...[
                      _buildSwitchRow(
                        'Buluşmayı Kilitle',
                        'Buluşman artık kullanıcıların karşısına çıkmaz.',
                        isLocked,
                        (val) {
                          setState(() => isLocked = val);
                        },
                      ),
                      _thinDivider(),
                      _buildExpandableRow(
                        'Görünürlük Seçenekleri',
                        'Buluşmanın hangi kullanıcıların karşısına çıkacağını düzenlersin.',
                      ),
                      _thinDivider(),
                    ] else
                      _thinDivider(),

                    _buildSimpleActionRow('Buluşmayı Bildir'),
                    _thinDivider(),

                    _buildSimpleActionRow(
                      'Buluşmadan Ayrıl',
                      textColor: AppColors.primaryColor,
                      onTap: _onLeaveEventTap,
                    ),

                    if (isCreator) ...[
                      _thinDivider(),
                      _buildSimpleActionRow(
                        'Buluşmayı İptal Et',
                        textColor: AppColors.primaryColor,
                        onTap: _onCancelEventTap,
                      ),
                    ],
                  ],
                ),

                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillRow({
    required String title,
    required String value,
    IconData? icon,
    VoidCallback? onTap,
    bool showTrailing = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(title, style: _labelStyle),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              constraints: BoxConstraints(maxWidth: 240.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFDDEFF5),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14.sp, color: const Color(0xFF4A6572)),
                    SizedBox(width: 6.w),
                  ],
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  if (showTrailing) ...[
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.keyboard_arrow_right,
                      size: 18.sp,
                      color: const Color(0xFF4A6572),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _labelStyle),
                SizedBox(height: 6.h),
                Text(subtitle, style: _subLabelStyle),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.primaryColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableRow(String title, String subtitle) {
    return InkWell(
      onTap: () {
        // expand / navigate
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _labelStyle),
                  SizedBox(height: 6.h),
                  Text(subtitle, style: _subLabelStyle),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 22.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleActionRow(
    String title, {
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Text(
          title,
          style: _labelStyle.copyWith(
            color: textColor ?? Colors.black87,
            fontWeight: textColor != null ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _thinDivider() {
    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
      child: const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
    );
  }
}
