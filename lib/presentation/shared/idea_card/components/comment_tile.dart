// presentation/idea/view/components/comment_tile.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/providers/idea_providers.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/feed/idea/idea_comment_entity.dart';
import 'package:outnest/domain/entities/feed/idea/idea_entity.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/presentation/shared/idea_card/components/vote_buttons.dart';
import 'package:outnest/presentation/shared/post_card/countdown_timer.dart';

/// A single comment row in the [IdeaDetailPage] thread.
///
/// Owns its own optimistic vote state but is otherwise a leaf —
/// nesting and reply-toggling are handled by the parent
/// [CommentThread] which knows the full branch.
class CommentTile extends HookConsumerWidget {
  const CommentTile({
    required this.comment,
    required this.onReply,
    required this.onToggleReplies,
    required this.repliesOpen,
    super.key,
  });

  final IdeaCommentEntity comment;
  final VoidCallback onReply;
  final VoidCallback onToggleReplies;
  final bool repliesOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(ideaRepositoryProvider);

    final vote = useState<IdeaVoteType?>(comment.currentUserVote);
    final likeCount = useState<int>(comment.likeCount);
    final dislikeCount = useState<int>(comment.dislikeCount);

    useEffect(
      () {
        vote.value = comment.currentUserVote;
        likeCount.value = comment.likeCount;
        dislikeCount.value = comment.dislikeCount;
        return null;
      },
      [
        comment.id,
        comment.currentUserVote,
        comment.likeCount,
        comment.dislikeCount,
      ],
    );

    Future<void> handleVote(IdeaVoteType tapped) async {
      final prevVote = vote.value;
      final prevLike = likeCount.value;
      final prevDislike = dislikeCount.value;

      _applyOptimisticVote(
        tapped: tapped,
        existing: prevVote,
        vote: vote,
        likeCount: likeCount,
        dislikeCount: dislikeCount,
      );

      try {
        await repo.setCommentVote(
          ideaId: comment.ideaId,
          commentId: comment.id,
          type: tapped,
        );
      } catch (_) {
        vote.value = prevVote;
        likeCount.value = prevLike;
        dislikeCount.value = prevDislike;
      }
    }

    final author = comment.author;
    final hasAvatar =
        author.profileImageUrl.isNotEmpty &&
        author.profileImageUrl.startsWith('http');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: hasAvatar
                    ? CachedNetworkImageProvider(
                        fixEmulatorUrl(author.profileImageUrl),
                      )
                    : AssetImage(FileService.defaultProfileImageUrl())
                          as ImageProvider,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '@${author.username}',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        CountdownTimer(
                          targetTime: comment.createdAt,
                          isEvent: false,
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 11.sp,
                            color: const Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      comment.content,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 13.sp,
                        color: const Color(0xFF1A1A1A),
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    VoteButtons(
                      vote: vote.value,
                      likeCount: likeCount.value,
                      dislikeCount: dislikeCount.value,
                      commentCount: comment.replyCount,
                      onLike: () => handleVote(IdeaVoteType.like),
                      onDislike: () => handleVote(IdeaVoteType.dislike),
                      onComment: onReply,
                      iconSize: 18.sp,
                    ),
                  ],
                ),
              ),
              Icon(
                Symbols.more_vert,
                size: 18.sp,
                color: const Color(0xFF8E8E93),
              ),
            ],
          ),
          if (comment.replyCount > 0)
            Padding(
              padding: EdgeInsets.only(left: 36.w, top: 4.h),
              child: GestureDetector(
                onTap: onToggleReplies,
                child: Text(
                  repliesOpen
                      ? 'Yanıtları gizle'
                      : '${comment.replyCount} yanıtı göster',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _applyOptimisticVote({
  required IdeaVoteType tapped,
  required IdeaVoteType? existing,
  required ValueNotifier<IdeaVoteType?> vote,
  required ValueNotifier<int> likeCount,
  required ValueNotifier<int> dislikeCount,
}) {
  if (existing == null) {
    vote.value = tapped;
    if (tapped == IdeaVoteType.like) {
      likeCount.value++;
    } else {
      dislikeCount.value++;
    }
    return;
  }
  if (existing == tapped) {
    vote.value = null;
    if (tapped == IdeaVoteType.like) {
      likeCount.value--;
    } else {
      dislikeCount.value--;
    }
    return;
  }
  vote.value = tapped;
  if (tapped == IdeaVoteType.like) {
    likeCount.value++;
    dislikeCount.value--;
  } else {
    dislikeCount.value++;
    likeCount.value--;
  }
}
