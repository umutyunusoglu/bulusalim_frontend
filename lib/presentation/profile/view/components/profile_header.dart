import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.fullName,
    required this.username,
    required this.isCurrentUser,
    required this.onShareTap,
    super.key,
  });

  final String fullName;
  final String username;
  final bool isCurrentUser;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.secondary;
    final onSurface = theme.colorScheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 5.h),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    fullName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.w500,
                      fontSize: 20.sp,
                      color: onSurface,
                      height: 1.0.sp,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    username,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.w400,
                      fontSize: 12.sp,
                      color: secondaryColor,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: onShareTap,
          child: Icon(
            Icons.share_outlined,
            color: AppColors.darkBackgroundColor,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 8.w),
        if (isCurrentUser)
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Icon(
              Symbols.settings,
              color: AppColors.darkBackgroundColor,
              size: 24.sp,
            ),
          )
        else
          SizedBox(width: 24.sp),
        SizedBox(width: 8.w),
      ],
    );
  }
}
