import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/presentation/home/view/components/post/small_stacked_avatars.dart';

class FollowedBySection extends StatelessWidget {
  const FollowedBySection({
    super.key,
    required this.commonFollowers,
  });

  final List<CompactUserEntity> commonFollowers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatars = <String>[];
    var commonCount = commonFollowers.length;

    if (commonCount == 0) {
      return const SizedBox.shrink();
    }

    if (commonCount == 1) {
      avatars.add(commonFollowers.first.profileImageUrl);
      commonCount -= 1;
    } else if (commonCount >= 2) {
      avatars
        ..add(commonFollowers[0].profileImageUrl)
        ..add(commonFollowers[1].profileImageUrl);
      commonCount -= 2;
    }

    final showAdditional = commonCount > 0;
    final namesText = commonFollowers
        .take(2)
        .map((user) => user.username)
        .join(', ');

    return Row(
      children: [
        SmallStackedAvatars(
          profileImageUrls: avatars,
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
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(text: namesText),
                  if (showAdditional) ...[
                    const TextSpan(text: ' ve '),
                    TextSpan(text: '$commonCount diğer kişi'),
                  ],
                  const TextSpan(text: ' tarafından takip ediliyor.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
