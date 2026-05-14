// presentation/idea/view/components/comment_thread.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:outnest/application/providers/idea_providers.dart';
import 'package:outnest/domain/entities/feed/idea/idea_comment_entity.dart';
import 'package:outnest/presentation/shared/idea_card/components/comment_tile.dart';

/// A new comment to splice into the tree without a round-trip.
///
/// [IdeaDetailPage] emits one of these through [CommentThread]'s
/// `insertSignal` after a successful `addComment`. Whichever
/// [CommentThread] in the recursive tree currently renders the
/// matching parent branch appends the comment to its local list.
class PendingInsert {
  const PendingInsert({required this.parentId, required this.comment});

  /// The parent the new comment belongs under. `null` means it's a
  /// top-level reply to the idea itself — that path is owned by the
  /// detail page's stream provider, not this widget.
  final String? parentId;
  final IdeaCommentEntity comment;
}

/// Renders a list of [IdeaCommentEntity] and, recursively, every
/// branch the user has expanded.
///
/// Replies load lazily — tapping "X yanıtı göster" triggers a single
/// [IdeaRepository.getComments] call. A 10-deep chain that the user
/// never expands costs zero reads.
///
/// **Optimistic inserts.** After the composer posts a reply,
/// [IdeaDetailPage] pushes the newly created entity through
/// [insertSignal]. The thread holding the matching parent splices
/// it into its local list — no Firestore round-trip, no flicker.
///
/// Depth indentation is bounded by [maxIndentDepth] so deep chains
/// don't crawl off-screen.
class CommentThread extends HookConsumerWidget {
  const CommentThread({
    required this.ideaId,
    required this.comments,
    required this.onReplyTo,
    required this.insertSignal,
    this.depth = 0,
    this.maxIndentDepth = 4,
    super.key,
  });

  final String ideaId;
  final List<IdeaCommentEntity> comments;
  final void Function(IdeaCommentEntity target) onReplyTo;
  final ValueNotifier<PendingInsert?> insertSignal;
  final int depth;
  final int maxIndentDepth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openBranches = useState<Map<String, List<IdeaCommentEntity>>>({});
    final loadingBranches = useState<Set<String>>({});

    final repo = ref.watch(ideaRepositoryProvider);

    // Ref mirror of the latest open-branches map. The insert
    // listener captured below is a closure pinned at first build;
    // without this ref it would keep reading the empty map from
    // that build and miss any branch the user expanded later.
    final openBranchesRef = useRef<Map<String, List<IdeaCommentEntity>>>(
      openBranches.value,
    );
    openBranchesRef.value = openBranches.value;

    // Same trick for the visible-comments list. The depth=N thread
    // needs to know which parents IT renders to decide whether a
    // signal belongs to it; if we read `comments` directly from the
    // closure, we'd see the initial prop forever.
    final commentsRef = useRef<List<IdeaCommentEntity>>(comments);
    commentsRef.value = comments;

    Future<void> toggle(IdeaCommentEntity comment) async {
      if (openBranches.value.containsKey(comment.id)) {
        final next = {...openBranches.value}..remove(comment.id);
        openBranches.value = next;
        return;
      }

      loadingBranches.value = {...loadingBranches.value, comment.id};
      try {
        final replies = await repo.getComments(
          ideaId: ideaId,
          parentCommentId: comment.id,
        );
        openBranches.value = {...openBranches.value, comment.id: replies};
      } finally {
        final next = {...loadingBranches.value}..remove(comment.id);
        loadingBranches.value = next;
      }
    }

    // Splice incoming optimistic inserts into the branch they
    // belong to. If the branch isn't open yet, we open it (load
    // siblings) and then append — that way a user who replies to a
    // comment whose thread they hadn't expanded still sees their
    // reply immediately, alongside any older replies from others.
    //
    // Only the thread that owns the matching parent acts; every
    // other thread sees the signal and ignores it. We use a ref to
    // ensure the depth=N+1 thread can claim a parent that depth=N
    // doesn't own — without this, the recursive structure means
    // each thread only knows its own open-branch set.
    useEffect(() {
      void onSignal() {
        final pending = insertSignal.value;
        debugPrint(
          '[CommentThread depth=$depth] signal fired, '
          'pending=${pending == null ? "null" : "parent=${pending.parentId} id=${pending.comment.id}"}, '
          'openBranches=${openBranchesRef.value.keys.toList()}, '
          'visibleParents=${commentsRef.value.map((c) => c.id).toList()}',
        );
        if (pending == null) return;

        final parentId = pending.parentId;
        if (parentId == null) return;

        // The thread that owns this parent is the one rendering it
        // as a tile — i.e. the parent appears in `comments`. The
        // depth=N+1 thread (rendering the parent's children) never
        // owns the parent itself, so this check correctly routes
        // the signal to the one thread that should act.
        final ownsParent = commentsRef.value.any((c) => c.id == parentId);
        if (!ownsParent) {
          debugPrint(
            '[CommentThread depth=$depth] does not own $parentId, skip',
          );
          return;
        }

        final existing = openBranchesRef.value[parentId];

        // Case 1: branch already open → splice the new comment in.
        if (existing != null) {
          if (existing.any((c) => c.id == pending.comment.id)) {
            debugPrint('[CommentThread depth=$depth] duplicate, skip');
            return;
          }
          debugPrint(
            '[CommentThread depth=$depth] splicing into open $parentId',
          );
          openBranches.value = {
            ...openBranches.value,
            parentId: [...existing, pending.comment],
          };
          return;
        }

        // Case 2: branch is closed → open it (which fetches any
        // existing siblings), then append our new comment so the
        // user sees it even if older replies came back too.
        debugPrint(
          '[CommentThread depth=$depth] auto-opening $parentId',
        );
        loadingBranches.value = {...loadingBranches.value, parentId};
        () async {
          try {
            final siblings = await repo.getComments(
              ideaId: ideaId,
              parentCommentId: parentId,
            );
            final alreadyHasOurs = siblings.any(
              (c) => c.id == pending.comment.id,
            );
            openBranches.value = {
              ...openBranches.value,
              parentId: alreadyHasOurs
                  ? siblings
                  : [...siblings, pending.comment],
            };
          } finally {
            final next = {...loadingBranches.value}..remove(parentId);
            loadingBranches.value = next;
          }
        }();
      }

      insertSignal.addListener(onSignal);
      return () => insertSignal.removeListener(onSignal);
    }, [insertSignal]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final comment in comments) ...[
          CommentTile(
            key: ValueKey('comment_${comment.id}'),
            comment: comment,
            onReply: () => onReplyTo(comment),
            onToggleReplies: () => toggle(comment),
            repliesOpen: openBranches.value.containsKey(comment.id),
          ),
          if (loadingBranches.value.contains(comment.id))
            Padding(
              padding: EdgeInsets.only(left: _indentFor(depth + 1), top: 4.h),
              child: SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (openBranches.value[comment.id] != null)
            _IndentedBranch(
              indent: _indentFor(depth + 1),
              child: CommentThread(
                ideaId: ideaId,
                comments: openBranches.value[comment.id]!,
                onReplyTo: onReplyTo,
                insertSignal: insertSignal,
                depth: depth + 1,
                maxIndentDepth: maxIndentDepth,
              ),
            ),
        ],
      ],
    );
  }

  double _indentFor(int d) {
    final effective = d > maxIndentDepth ? maxIndentDepth : d;
    return 24.0 * effective;
  }
}

class _IndentedBranch extends StatelessWidget {
  const _IndentedBranch({required this.indent, required this.child});

  final double indent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Color(0xFFEFEFEF), width: 1),
          ),
        ),
        padding: EdgeInsets.only(left: 8.w),
        child: child,
      ),
    );
  }
}
