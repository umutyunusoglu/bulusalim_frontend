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
import 'package:outnest/core/constants/theme/color_themes.dart';
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

    // Tapping the comment icon on the idea card while already on
    // the detail page should NOT push another copy of this page.
    // Instead, treat it as "start a top-level comment": clear any
    // active reply target and focus the composer.
    void focusComposerForTopLevel() {
      replyTarget.value = null;
      composerFocus.requestFocus();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      // AppBar shares the page's grey background so the top doesn't
      // read as a separate white strip — same surface, edge to edge.
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
      ),
      // Stack instead of Column: the composer floats over the list,
      // letting the grey page background flow uninterrupted behind
      // it. The list reserves enough bottom padding so its last
      // comment never sits under the pill.
      body: SafeArea(
        child: Stack(
          children: [
            ideaAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e')),
              data: (idea) {
                if (idea == null) {
                  return const Center(child: Text('Fikir bulunamadı.'));
                }
                return ListView(
                  padding: EdgeInsets.only(bottom: 96.h),
                  children: [
                    IdeaCard(
                      idea: idea,
                      // Override the default push-to-detail so we
                      // don't stack another IdeaDetailPage on top
                      // of this one.
                      onCommentTap: focusComposerForTopLevel,
                    ),
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
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _Composer(
                controller: composerController,
                focusNode: composerFocus,
                replyTarget: replyTarget.value,
                onCancelReply: () => replyTarget.value = null,
                onSend: sendComment,
                busy: isPosting.value,
              ),
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

    return Padding(
      // No background, no top border — the composer is meant to
      // float over the grey page. We only pad it so the pill has
      // breathing room from the screen edges and the keyboard.
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
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
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: 4,
                  minLines: 1,
                  // Idle state: white text on the coral pill so the
                  // hint reads as a label, not a placeholder. Focused
                  // state: dark text on white, conventional input.
                  // We drive both colors from the same flag so they
                  // never desync — which is what caused the earlier
                  // bug where the hint stayed white on a white fill.
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
                    // InputDecoration.filled wins over any ambient
                    // Material canvas color, so the coral pill
                    // renders even on the first frame — no more
                    // "white pill with coral border" flash.
                    filled: true,
                    fillColor: hasFocus || hasText
                        ? Colors.white
                        : AppColors.primaryColor,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      borderSide: hasFocus || hasText
                          ? const BorderSide(color: Color(0xFFEFEFEF))
                          : BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      borderSide: const BorderSide(color: Color(0xFFEFEFEF)),
                    ),
                    isCollapsed: true,
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
