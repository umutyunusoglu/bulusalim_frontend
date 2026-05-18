// presentation/idea/view/components/comment_tile.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/providers/idea_providers.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/feed/idea/idea_comment_entity.dart';
import 'package:outnest/domain/entities/feed/idea/idea_entity.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/presentation/shared/bottom_sheet_option.dart';
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
                    Text(
                      '@${author.username}',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 2.h),
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
              ),
              _MoreButton(comment: comment),
            ],
          ),

          SizedBox(height: 8.h),
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
          Align(
            alignment: Alignment.centerRight,
            child: VoteButtons(
              vote: vote.value,
              likeCount: likeCount.value,
              dislikeCount: dislikeCount.value,
              commentCount: comment.replyCount,
              onLike: () => handleVote(IdeaVoteType.like),
              onDislike: () => handleVote(IdeaVoteType.dislike),
              onComment: onReply,
              iconSize: 20.sp,
            ),
          ),
          if (comment.replyCount > 0)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: GestureDetector(
                onTap: onToggleReplies,
                child: Text(
                  repliesOpen
                      ? 'Yanıtları gizle'
                      : '${comment.replyCount} yanıtı göster',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12.sp,
                    color: AppColors.darkSlate,
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

/// Tappable more-actions button at the right edge of every comment.
///
/// Only the author sees the "Yorumu Sil" entry; non-authors get an
/// empty sheet for now. Kept as its own ConsumerWidget so the tile
/// above doesn't have to be rebuilt every time the auth provider
/// emits — the watch lives behind this much narrower boundary.
class _MoreButton extends ConsumerWidget {
  const _MoreButton({required this.comment});
  final IdeaCommentEntity comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIDProvider);
    final isMine =
        currentUserId != null && currentUserId == comment.author.userID;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          useRootNavigator: true,
          builder: (sheetContext) => CustomActionBottomSheet(
            options: [
              if (isMine)
                BottomSheetOption(
                  icon: Symbols.delete,
                  text: 'Yorumu Sil',
                  isDestructive: true,
                  onTap: () async {
                    sheetContext.pop();
                    await _confirmAndDeleteComment(
                      context,
                      ref,
                      ideaId: comment.ideaId,
                      commentId: comment.id,
                    );
                  },
                ),
              // TODO: share / report for non-authors when those
              // APIs land on IdeaRepository.
            ],
          ),
        );
      },
      child: Padding(
        // Bigger hit target than the visual icon — easier to tap
        // without enlarging the icon itself.
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        child: Icon(
          Symbols.more_vert,
          size: 18.sp,
          color: const Color(0xFF8E8E93),
        ),
      ),
    );
  }
}

/// Confirms with the user and soft-deletes the comment on accept.
///
/// Mirrors `_confirmAndDelete` in idea_card.dart — same pattern,
/// different repository call. Top-level so the dialog/snackbar
/// attach to the tile's context, not the dismissed bottom sheet.
Future<void> _confirmAndDeleteComment(
  BuildContext context,
  WidgetRef ref, {
  required String ideaId,
  required String commentId,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Yorumu Sil'),
      content: const Text('Bu yorumu silmek istediğine emin misin?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text(
            'Sil',
            style: TextStyle(color: Color(0xFFFF3B30)),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    await ref
        .read(ideaRepositoryProvider)
        .deleteComment(
          ideaId: ideaId,
          commentId: commentId,
        );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silinemedi: $e')),
      );
    }
  }
}
