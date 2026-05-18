// presentation/idea/view/components/idea_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/feed_providers.dart';
import 'package:outnest/application/providers/idea_providers.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/domain/entities/feed/idea/idea_entity.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/presentation/shared/bottom_sheet_option.dart';
import 'package:outnest/presentation/shared/idea_card/components/vote_buttons.dart';

/// Feed card for an [IdeaEntity] (the "Fikir Balonu" surface from
/// the design — see screenshot 1).
///
/// Designed to be lean: no per-card Firestore listeners, no manual
/// state synchronization. Vote state lives in two hooks and gets
/// reconciled with the entity on rebuild, so when the feed re-emits
/// (e.g. on refresh) the card picks up server-side numbers
/// transparently.
class IdeaCard extends HookConsumerWidget {
  const IdeaCard({
    required this.idea,
    this.onCommentTap,
    this.isDetailMode = false,
    super.key,
  });

  final IdeaEntity idea;
  final bool isDetailMode;

  /// Override for the comment-icon tap. When `null` (the feed case),
  /// the card pushes its own detail route. The detail page passes a
  /// callback here that focuses the composer instead — otherwise
  /// tapping the icon from within the detail page would push a new
  /// copy of the same detail page onto the navigator stack.
  final VoidCallback? onCommentTap;

  static const _textMain = Color(0xFF1A1A1A);
  static const _textGrey = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(ideaRepositoryProvider);

    // Local, optimistic vote state. Seeded from the entity, kept in
    // sync via the reconciliation effect below so a server refresh
    // doesn't get clobbered by stale local values.
    final vote = useState<IdeaVoteType?>(idea.currentUserVote);
    final likeCount = useState<int>(idea.likeCount);
    final dislikeCount = useState<int>(idea.dislikeCount);

    useEffect(() {
      vote.value = idea.currentUserVote;
      likeCount.value = idea.likeCount;
      dislikeCount.value = idea.dislikeCount;
      return null;
    }, [idea.id, idea.currentUserVote, idea.likeCount, idea.dislikeCount]);

    Future<void> handleVote(IdeaVoteType tapped) async {
      final prevVote = vote.value;
      final prevLike = likeCount.value;
      final prevDislike = dislikeCount.value;

      // Apply the same delta the repository will apply server-side.
      // Keeps the optimistic state mathematically identical to what
      // the transaction will produce.
      _applyOptimistic(
        tapped: tapped,
        existing: prevVote,
        vote: vote,
        likeCount: likeCount,
        dislikeCount: dislikeCount,
      );

      try {
        await repo.setVote(ideaId: idea.id, type: tapped);
      } catch (_) {
        vote.value = prevVote;
        likeCount.value = prevLike;
        dislikeCount.value = prevDislike;
      }
    }

    final Widget cardContent = Container(
      width: isDetailMode ? double.infinity : 361.w,
      margin: isDetailMode
          ? EdgeInsets.zero
          : EdgeInsets.only(bottom: 16.h, top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        borderRadius: isDetailMode
            ? BorderRadius.zero
            : BorderRadius.circular(16.r),
        border: isDetailMode
            ? null
            : Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(idea: idea),
          SizedBox(height: 12.h),
          Text(
            idea.content,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14.sp,
              color: _textMain,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12.h),
          // Just the vote/comment trio, right-aligned. The
          // timestamp lives in the header now (under @username),
          // matching the design where the date sits with the
          // author block rather than next to the actions.
          Align(
            alignment: Alignment.centerRight,
            child: VoteButtons(
              vote: vote.value,
              likeCount: likeCount.value,
              dislikeCount: dislikeCount.value,
              commentCount: idea.commentCount,
              commentsEnabled: idea.commentsEnabled,
              onLike: () => handleVote(IdeaVoteType.like),
              onDislike: () => handleVote(IdeaVoteType.dislike),
              // Use the override if the host page passed one
              // (detail page focuses the composer); otherwise the
              // feed default behavior is to open the detail page.
              onComment: onCommentTap ?? () => context.push('/idea/${idea.id}'),
            ),
          ),
        ],
      ),
    );

    if (isDetailMode) {
      return cardContent;
    }
    return Center(child: cardContent);
  }
}

/// Mirrors `IdeaRepositoryImpl._applyVoteDelta` so the UI's
/// optimistic state lands in the exact same place the server will.
void _applyOptimistic({
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
    // Toggle off.
    vote.value = null;
    if (tapped == IdeaVoteType.like) {
      likeCount.value--;
    } else {
      dislikeCount.value--;
    }
    return;
  }

  // Switch sides.
  vote.value = tapped;
  if (tapped == IdeaVoteType.like) {
    likeCount.value++;
    dislikeCount.value--;
  } else {
    dislikeCount.value++;
    likeCount.value--;
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.idea});
  final IdeaEntity idea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final creator = idea.creator;
    final avatarUrl = creator.profileImageUrl;
    final hasAvatar = avatarUrl.isNotEmpty && avatarUrl.startsWith('http');
    // Current user resolves to null when the auth provider is still
    // loading; treat that as "not the owner" so the menu falls
    // through to reader-side actions only.
    final currentUserId = ref.watch(currentUserIDProvider);
    final isMine = currentUserId != null && currentUserId == creator.userID;

    void goToProfile() {
      final id = creator.userID;
      if (id.isNotEmpty) context.push('/home/profile/$id');
    }

    void openActions() {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        useRootNavigator: true,
        builder: (sheetContext) => CustomActionBottomSheet(
          options: [
            if (isMine)
              BottomSheetOption(
                icon: Symbols.delete,
                text: 'Fikri Sil',
                isDestructive: true,
                onTap: () async {
                  sheetContext.pop();
                  await _confirmAndDelete(context, ref, idea.id);
                },
              ),
            // TODO: share / report / block options for non-owners —
            // mirror PostCard's _showOtherUserPostOptions when the
            // matching IdeaRepository APIs land.
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: goToProfile,
          child: CircleAvatar(
            radius: 20.r,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: hasAvatar
                ? CachedNetworkImageProvider(fixEmulatorUrl(avatarUrl))
                : AssetImage(FileService.defaultProfileImageUrl())
                      as ImageProvider,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: bold display name, then the @handle in grey
              // on the same line — matches the design's "Arda Yıldız
              // @arda11yildiz" pairing.
              Row(
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: goToProfile,
                      child: Text(
                        creator.nameSurname ?? creator.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                          color: IdeaCard._textMain,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      '@${creator.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 13.sp,
                        color: IdeaCard._textGrey,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              // Row 2: absolute date, not relative. The design uses
              // "30.04.2026" — calendar-style. We format with
              // intl's DateFormat for locale-aware separators.
              Text(
                _formatDate(idea.createdAt),
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12.sp,
                  color: IdeaCard._textGrey,
                ),
              ),
            ],
          ),
        ),
        if (isMine)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Symbols.more_vert, color: theme.colorScheme.secondary),
            onPressed: openActions,
          ),
      ],
    );
  }

  /// dd.MM.yyyy with zero-padded day and month. Pure-Dart so we
  /// don't drag in `intl` for a single format.
  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }
}

/// Confirms with the user and soft-deletes the idea on accept.
///
/// Top-level (rather than a method on _Header) so the dialog and
/// the snackbar attach to the card's context, not the bottom
/// sheet's — which has already been dismissed by the time we get
/// here.
Future<void> _confirmAndDelete(
  BuildContext context,
  WidgetRef ref,
  String ideaId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Fikri Sil'),
      content: const Text('Bu fikri silmek istediğine emin misin?'),
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
    await ref.read(ideaRepositoryProvider).deleteIdea(ideaId);
    // Reach into every feed tab's repository and prune the deleted
    // idea from its local stream. Cheaper than refresh() and keeps
    // the user's scroll position intact across tabs.
    for (final type in FeedType.values) {
      ref.read(feedRepositoryProvider(type)).removeItem(ideaId);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silinemedi: $e')),
      );
    }
  }
}
