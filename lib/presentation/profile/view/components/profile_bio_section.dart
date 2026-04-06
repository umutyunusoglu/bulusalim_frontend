import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileBioSection extends StatelessWidget {
  const ProfileBioSection({
    required this.bio,
    required this.school,
    super.key,
  });

  final String bio;
  final String school;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bio,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Icon(
              Icons.school_outlined,
              size: 16.sp,
              color: theme.disabledColor,
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                school,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: theme.disabledColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
