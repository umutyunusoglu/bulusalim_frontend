import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/presentation/chat/view/components/event_status_accordion_components/event_status_accordion_avatar.dart';
import 'package:outnest/presentation/shared/navigation/navigate_to_profile.dart';

class EventStatusAccordionApprovedRow extends StatelessWidget {
  const EventStatusAccordionApprovedRow({
    required this.user,
    required this.isCreator,
    required this.onRemove,
    super.key,
  });

  final CompactUserEntity user;
  final bool isCreator;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => navigateToProfile(context, user.userID),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            EventStatusAccordionAvatar(url: user.profileImageUrl),
            SizedBox(width: 12.w),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      user.username,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14.sp,
                        fontWeight: isCreator
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCreator) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(
                          color: AppColors.primaryColor,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        'buluşma sahibi',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isCreator)
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 14.sp,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
