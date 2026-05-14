// presentation/idea/view/components/idea_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/providers/idea_providers.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/feed/idea/idea_entity.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/presentation/shared/idea_card/components/vote_buttons.dart';
import 'package:outnest/presentation/shared/post_card/countdown_timer.dart';

/// Feed card for an [IdeaEntity] (the "Fikir Balonu" surface from
/// the design — see screenshot 1).
///
/// Designed to be lean: no per-card Firestore listeners, no manual
/// state synchronization. Vote state lives in two hooks and gets
/// reconciled with the entity on rebuild, so when the feed re-emits
/// (e.g. on refresh) the card picks up server-side numbers
/// transparently.
class IdeaCard extends HookConsumerWidget {
  const IdeaCard({required this.idea, super.key});

  final IdeaEntity idea;

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

    return Center(
      child: Container(
        width: 361.w,
        margin: EdgeInsets.only(bottom: 16.h, top: 8.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFEFEFEF)),
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
            Row(
              children: [
                CountdownTimer(
                  targetTime: idea.createdAt,
                  isEvent: false,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12.sp,
                    color: _textGrey,
                  ),
                ),
                const Spacer(),
                VoteButtons(
                  vote: vote.value,
                  likeCount: likeCount.value,
                  dislikeCount: dislikeCount.value,
                  commentCount: idea.commentCount,
                  commentsEnabled: idea.commentsEnabled,
                  onLike: () => handleVote(IdeaVoteType.like),
                  onDislike: () => handleVote(IdeaVoteType.dislike),
                  onComment: () => context.push('/idea/${idea.id}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

class _Header extends StatelessWidget {
  const _Header({required this.idea});
  final IdeaEntity idea;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final creator = idea.creator;
    final avatarUrl = creator.profileImageUrl;
    final hasAvatar = avatarUrl.isNotEmpty && avatarUrl.startsWith('http');

    void goToProfile() {
      final id = creator.userID;
      if (id.isNotEmpty) context.push('/home/profile/$id');
    }

    return Row(
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
              GestureDetector(
                onTap: goToProfile,
                child: Text(
                  creator.nameSurname ?? creator.username,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: IdeaCard._textMain,
                  ),
                ),
              ),
              Text(
                '@${creator.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12.sp,
                  color: IdeaCard._textGrey,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(Symbols.more_vert, color: theme.colorScheme.secondary),
          onPressed: () {
            // TODO: bottom sheet with share/report/delete actions,
            // mirroring PostCard. Left out here to keep IdeaCard
            // focused on the new feature surface — wire later.
          },
        ),
      ],
    );
  }
}
