import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

class ChatEventInfoChip extends StatelessWidget {
  const ChatEventInfoChip({
    required this.location,
    required this.startTime,
    required this.participantCount,
    this.onLocationTap,
    this.onTimeTap,
    this.onParticipantsTap,
    super.key,
  });

  final String location;
  final DateTime startTime;
  final int participantCount;
  final VoidCallback? onLocationTap;
  final VoidCallback? onTimeTap;
  final VoidCallback? onParticipantsTap;

  static final DateFormat _dateFormat = DateFormat('dd MMMM HH.mm', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    final dateStr = _dateFormat.format(startTime);

    return Row(
      mainAxisSize: MainAxisSize.min, // Alanı minimumda tutar
      children: [
        // 1. Konum (FLEXIBLE KALDIRILDI)
        GestureDetector(
          onTap: onLocationTap,
          behavior: HitTestBehavior.opaque,
          child: _buildItem(Icons.location_on_outlined, location),
        ),
        SizedBox(width: 8.w),

        // 2. Tarih/Saat
        GestureDetector(
          onTap: onTimeTap,
          behavior: HitTestBehavior.opaque,
          child: _buildItem(Icons.access_time, dateStr),
        ),
        SizedBox(width: 8.w),

        // 3. Kişi Sayısı
        GestureDetector(
          onTap: onParticipantsTap,
          behavior: HitTestBehavior.opaque,
          child: _buildItem(Icons.people_outline, participantCount.toString()),
        ),
      ],
    );
  }

  Widget _buildItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.sp, color: AppColors.darkSlate),
        SizedBox(width: 2.w),
        // FLEXIBLE KALDIRILDI
        Text(
          text,
          maxLines: 1,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 11.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.locationBadgeText,
          ),
        ),
      ],
    );
  }
}
