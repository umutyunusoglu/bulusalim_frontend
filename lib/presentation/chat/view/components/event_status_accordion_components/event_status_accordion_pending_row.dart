import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/presentation/chat/view/components/event_status_accordion_components/event_status_accordion_avatar.dart';

class EventStatusAccordionPendingRow extends StatelessWidget {
  const EventStatusAccordionPendingRow({
    required this.user,
    required this.onAccept,
    required this.onReject,
    super.key,
  });

  final CompactUserEntity user;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          EventStatusAccordionAvatar(url: user.profileImageUrl),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              user.username,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onAccept,
                child: Container(
                  width: 26.w,
                  height: 26.w,
                  decoration: const BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 16.sp),
                ),
              ),
              SizedBox(width: 12.w),
              GestureDetector(
                onTap: onReject,
                child: Container(
                  width: 26.w,
                  height: 26.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 16.sp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
