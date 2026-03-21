import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

class CommunityEventInfoCard extends StatelessWidget {
  const CommunityEventInfoCard({
    required this.profileImageUrl,
    required this.communityName,
    required this.eventName,
    required this.displayAddress,
    required this.startTime,
    required this.maxParticipants,
    required this.category,
    super.key,
    this.link,
  });

  final String profileImageUrl;
  final String communityName;
  final String eventName;
  final String displayAddress;
  final DateTime startTime;
  final int maxParticipants;
  final String category;
  final String? link;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${startTime.day} ${_monthName(startTime.month)} '
        '${startTime.hour.toString().padLeft(2, '0')}.'
        '${startTime.minute.toString().padLeft(2, '0')}';

    final emoji = AppConfig.categories[category] ?? '🎉';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: Row(
        children: [
          SizedBox(
            width: 50.w,
            height: 50.h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Profil fotoğrafı
                CircleAvatar(
                  radius: 25.r,
                  backgroundColor: AppColors.inputFillColor,
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl.isEmpty
                      ? Icon(
                          Icons.group,
                          size: 20.sp,
                          color: AppColors.textGrey,
                        )
                      : null,
                ),

                // Kategori emojisi — sağ alt köşe
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 22.w,
                    height: 22.h,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.backgroundColor,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 12.w),

          // ETKİNLİK BİLGİLERİ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ETKİNLİK ADI
                Text(
                  eventName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onBackgroundColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 4.h),

                // KONUM + SAAT + KATİLIMCI
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12.sp,
                      color: AppColors.tertiaryColor,
                    ),
                    SizedBox(width: 2.w),
                    Flexible(
                      child: Text(
                        displayAddress,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.tertiaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    SizedBox(width: 8.w),

                    Icon(
                      Icons.access_time,
                      size: 12.sp,
                      color: AppColors.tertiaryColor,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.tertiaryColor,
                      ),
                    ),

                    SizedBox(width: 8.w),

                    Icon(
                      Symbols.group,
                      size: 12.sp,
                      color: AppColors.tertiaryColor,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '$maxParticipants',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.tertiaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // BİLET İKONU — sadece link varsa göster
          if (link != null && link!.isNotEmpty) ...[
            SizedBox(width: 8.w),
            Icon(
              Symbols.confirmation_number,
              size: 24.sp,
              color: AppColors.primaryColor,
            ),
          ],
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '',
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
    return months[month];
  }
}
