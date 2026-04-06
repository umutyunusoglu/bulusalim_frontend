import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/presentation/home/view/components/post/small_stacked_avatars.dart';

class CommonMembersRow extends StatelessWidget {
  const CommonMembersRow({
    required this.commonMembers,
    required this.theme,
  });

  final List<dynamic> commonMembers;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SmallStackedAvatars(
          profileImageUrls: commonMembers
              .take(2)
              .map((e) => e.profileImageUrl as String)
              .toList(),
          size: 24.r,
          overlap: 9.r,
          borderWidth: 0.sp,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 11.sp,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(
                    text: '${commonMembers.first.username}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' ve '),
                  TextSpan(
                    text: '${commonMembers.length - 1} diğer kişi',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' bu topluluğa katıldı.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
