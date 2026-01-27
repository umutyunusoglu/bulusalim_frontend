import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

class EventInfoChip extends StatelessWidget {
  const EventInfoChip({
    required this.startTime,
    required this.participantCount,
    required this.capacity,
    this.onParticipantsTap,
    super.key,
  });

  final DateTime startTime;
  final int participantCount;
  final int capacity;
  final VoidCallback? onParticipantsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24.h,
      constraints: BoxConstraints(minWidth: 155.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: AppColors.infoBadgeBackground,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Tarih/Saat
          Icon(
            Icons.access_time,
            size: 12.sp,
            color: AppColors.infoBadgeText,
          ),
          SizedBox(width: 4.w),
          Text(
            _formatEventDate(startTime),
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.infoBadgeText,
            ),
          ),

          SizedBox(width: 8.w),

          // 2. Kişi Sayısı - TIKLANABILIR
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                print('🎯 Katılımcı ikonuna tıklandı!'); // Debug
                onParticipantsTap?.call();
              },
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 12.sp,
                      color: AppColors.infoBadgeText,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '$participantCount',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.infoBadgeText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: 5.w),

          // 3. Kilit
          Icon(
            Icons.lock_outline,
            size: 12.sp,
            color: AppColors.infoBadgeText,
          ),
        ],
      ),
    );
  }

  String _formatEventDate(DateTime date) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    final day = date.day;
    final monthName = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $monthName $hour.$minute';
  }
}
