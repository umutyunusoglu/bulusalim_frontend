// presentation/idea/view/idea_detail_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/providers/idea_providers.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/feed/idea/idea_comment_entity.dart';
import 'package:outnest/domain/services/file_service.dart';

import 'package:outnest/presentation/shared/idea_card/components/comment_thread.dart';
import 'package:outnest/presentation/shared/idea_card/idea_cart.dart';

/// Detail surface for an idea (screenshot 3).
///
/// Composition:
///   - The idea itself rendered as a regular [IdeaCard], reused so
///     the visuals never drift between feed and detail.
///   - The top-level comment list streamed from Firestore so new
///     comments appear in real time across users.
///   - A sticky "Yorum yaz." composer pinned to the bottom; when the
///     user is replying to a specific comment we surface a small
///     "Replying to @user" chip above it.
class IdeaDetailPage extends HookConsumerWidget {
  const IdeaDetailPage({required this.ideaId, super.key});

  final String ideaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(ideaRepositoryProvider);
    final ideaAsync = ref.watch(ideaStreamProvider(ideaId));
    final commentsAsync = ref.watch(topLevelCommentsProvider(ideaId));

    final replyTarget = useState<IdeaCommentEntity?>(null);
    final composerController = useTextEditingController();
    final composerFocus = useFocusNode();
    final isPosting = useState(false);

    // Notifier we pulse with the newly-created comment after a
    // successful post. CommentThread listens and splices the entity
    // into the matching open branch — no Firestore round-trip, no
    // flicker. Top-level replies aren't sent through here because
    // topLevelCommentsProvider's stream already delivers them.
    final insertSignal = useState<PendingInsert?>(null);

    Future<void> sendComment() async {
      final text = composerController.text.trim();
      if (text.isEmpty || isPosting.value) return;
      final target = replyTarget.value;

      isPosting.value = true;
      // Clear the composer eagerly so the next keystroke isn't
      // queued behind a 200ms network call. We restore on error.
      composerController.clear();
      replyTarget.value = null;

      try {
        final created = await repo.addComment(
          ideaId: ideaId,
          parentCommentId: target?.id,
          content: text,
        );

        if (target != null) {
          debugPrint(
            '[IdeaDetailPage] emitting insert signal: '
            'parent=${target.id} comment=${created.id}',
          );
          // Pulse: null → entity. The null reset makes consecutive
          // replies to the same parent each register as a change
          // even if the entity reference happens to match.
          insertSignal.value = null;
          insertSignal.value = PendingInsert(
            parentId: target.id,
            comment: created,
          );
        }
      } catch (e) {
        // Roll back the composer so the user doesn't lose what they
        // typed if the network failed.
        composerController.text = text;
        replyTarget.value = target;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Yorum gönderilemedi: $e')),
          );
        }
      } finally {
        isPosting.value = false;
      }
    }

    void startReply(IdeaCommentEntity target) {
      replyTarget.value = target;
      composerFocus.requestFocus();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Balon Yorumları',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w600,
            fontSize: 17.sp,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ideaAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Hata: $e')),
                data: (idea) {
                  if (idea == null) {
                    return const Center(child: Text('Fikir bulunamadı.'));
                  }
                  return ListView(
                    padding: EdgeInsets.only(bottom: 96.h),
                    children: [
                      IdeaCard(idea: idea),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        child: commentsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (e, _) => Text('Yorumlar yüklenemedi: $e'),
                          data: (comments) {
                            if (comments.isEmpty) {
                              return Padding(
                                padding: EdgeInsets.all(24.h),
                                child: Center(
                                  child: Text(
                                    'İlk yorumu sen yaz.',
                                    style: TextStyle(
                                      fontFamily: 'SF Pro Display',
                                      fontSize: 13.sp,
                                      color: const Color(0xFF8E8E93),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return CommentThread(
                              ideaId: ideaId,
                              comments: comments,
                              onReplyTo: startReply,
                              insertSignal: insertSignal,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _Composer(
              controller: composerController,
              focusNode: composerFocus,
              replyTarget: replyTarget.value,
              onCancelReply: () => replyTarget.value = null,
              onSend: sendComment,
              busy: isPosting.value,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky composer at the bottom of [IdeaDetailPage]. Coral pill in
/// the resting state (matches screenshot 3); expands into an input
/// row once focused.
class _Composer extends HookConsumerWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.replyTarget,
    required this.onCancelReply,
    required this.onSend,
    required this.busy,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final IdeaCommentEntity? replyTarget;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserEntityProvider).requireValue;
    final hasFocus = useListenable(focusNode).hasFocus;
    final hasText = useListenableSelector(
      controller,
      () => controller.text.trim().isNotEmpty,
    );

    final hasUrl =
        user?.profileImageUrl.isNotEmpty == true &&
        user!.profileImageUrl.startsWith('http');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEFEFEF))),
      ),
      padding: EdgeInsets.fromLTRB(
        16.w,
        10.h,
        16.w,
        10.h + MediaQuery.of(context).viewInsets.bottom * 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyTarget != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Text(
                    '@${replyTarget!.author.username} kullanıcısına yanıt',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12.sp,
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onCancelReply,
                    child: Icon(
                      Symbols.close,
                      size: 16.sp,
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: hasUrl
                    ? CachedNetworkImageProvider(
                        fixEmulatorUrl(user.profileImageUrl),
                      )
                    : AssetImage(FileService.defaultProfileImageUrl())
                          as ImageProvider,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: hasFocus || hasText
                        ? Colors.white
                        : const Color(0xFFFF6B4A),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: hasFocus || hasText
                          ? const Color(0xFFEFEFEF)
                          : Colors.transparent,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 4.h,
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    maxLines: 4,
                    minLines: 1,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 14.sp,
                      color: hasFocus || hasText
                          ? const Color(0xFF1A1A1A)
                          : Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Yorum yaz.',
                      hintStyle: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14.sp,
                        color: hasFocus || hasText
                            ? const Color(0xFF8E8E93)
                            : Colors.white,
                      ),
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  ),
                ),
              ),
              if (hasFocus || hasText) ...[
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: busy ? null : onSend,
                  child: Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B4A),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Symbols.arrow_upward,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
