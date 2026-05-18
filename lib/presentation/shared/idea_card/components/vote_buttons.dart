// presentation/idea/view/components/vote_buttons.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/feed/idea/idea_entity.dart';

/// The like / dislike / comment triplet used on both [IdeaCard] and
/// comment tiles.
///
/// Visually: outline icons with a count to their right, separated by
/// modest horizontal padding — matches the design in screenshot 1
/// and screenshot 3 ("16  16  16" trios).
///
/// The widget is stateless; vote/count state lives in the parent so
/// optimistic updates and rollbacks are handled in one place per
/// surface (card vs. comment tile).
class VoteButtons extends StatelessWidget {
  const VoteButtons({
    required this.vote,
    required this.likeCount,
    required this.dislikeCount,
    required this.commentCount,
    required this.onLike,
    required this.onDislike,
    required this.onComment,
    this.commentsEnabled = true,
    this.iconSize,
    super.key,
  });

  final IdeaVoteType? vote;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final bool commentsEnabled;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onComment;

  /// Defaults to 22.sp; override for nested comment tiles where the
  /// trio sits in a denser layout.
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final size = iconSize ?? 20.sp;
    final liked = vote == IdeaVoteType.like;
    final disliked = vote == IdeaVoteType.dislike;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconCount(
          icon: liked ? Icons.thumb_up : Icons.thumb_up_outlined,
          count: likeCount,
          active: liked,
          size: size,
          onTap: onLike,
        ),
        SizedBox(width: 14.w),
        _IconCount(
          icon: disliked ? Icons.thumb_down : Icons.thumb_down_outlined,
          count: dislikeCount,
          active: disliked,
          size: size,
          onTap: onDislike,
        ),
        SizedBox(width: 14.w),
        _IconCount(
          icon: Symbols.add_comment,
          count: commentCount,
          active: false,
          size: size,
          onTap: commentsEnabled ? onComment : null,
          dimmed: !commentsEnabled,
        ),
      ],
    );
  }
}

class _IconCount extends StatelessWidget {
  const _IconCount({
    required this.icon,
    required this.count,
    required this.active,
    required this.size,
    required this.onTap,
    this.dimmed = false,
  });

  final IconData icon;
  final int count;
  final bool active;
  final double size;
  final VoidCallback? onTap;
  final bool dimmed;

  /// Resting color for thumbs and the comment add-box. Matches the
  /// dark indigo/navy used in the design — gives the row a bit of
  /// brand-flavored personality without competing with the coral
  /// accents used for primary actions (composer pill, send button).
  static const _restingColor = Color(0xFF2C3E8C);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = dimmed
        ? const Color(0xFFC7C7CC)
        : active
        ? theme.colorScheme.secondary
        : AppColors.secondaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: size, color: color),
            SizedBox(width: 4.w),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14.sp,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
