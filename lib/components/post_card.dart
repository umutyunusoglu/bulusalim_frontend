import 'package:cached_network_image/cached_network_image.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/bottomsheetoption.dart';
import 'package:outnest/components/countdown_timer.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/core/utils/types/enums/emote_enum.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/post_repository.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/analytics/event_configs/pin_post_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/remove_emote_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/send_emote_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/unpin_post_analytics_config.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/security_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/screens/home/post%20components/content_tag_chip.dart';
import 'package:outnest/screens/home/post%20components/emoji_chip.dart';
import 'package:outnest/screens/home/post%20components/small_stacked_avatars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    required this.post,
    required this.user,
    this.onPinToggle,
    this.onPostDeleted,

    super.key,
  });

  final PostEntity post;
  final CompactUserEntity? user;

  // Sabitleme durumu değişince üst widget'ı (Feed/Grid) haberdar edecek fonksiyon
  final void Function(bool isPinned)? onPinToggle;
  final VoidCallback? onPostDeleted;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // --- RENK SABİTLERİ ---
  static const Color _kTextMainColor = Color(0xFF1A1A1A);
  static const Color _kTextGreyColor = Color(0xFF8E8E93);
  static const Color _kInactiveIndicatorColor = Color(0xFFD9D9D9);

  // --- STATE DEĞİŞKENLERİ ---
  late int _likeCount;
  late int _clapCount;
  late int _eggCount;

  bool _isLikedByMe = false;
  bool _isClappedByMe = false;
  bool _isEggedByMe = false;

  bool _amIFollowingPostCreator = false;
  bool _isPostMine = false;

  // Pin durumunu yerel state'te tutuyoruz
  bool _isPinned = false;

  bool isVisible = true;

  late final PostRepository _postRepository;
  late final SessionService _sessionService;
  late final String _myUserId;

  @override
  void initState() {
    super.initState();
    _postRepository = getIt<PostRepository>();
    _sessionService = getIt<SessionService>();
    _myUserId = _sessionService.currentUser?.userID ?? '';

    _likeCount = widget.post.emoteCounts[EmoteEnum.heart] ?? 0;
    _clapCount = widget.post.emoteCounts[EmoteEnum.clap] ?? 0;
    _eggCount = widget.post.emoteCounts[EmoteEnum.egg] ?? 0;

    // Başlangıç değerini widget'tan al
    _updateFollowingStatus();
    _sessionService.stateListenable.addListener(_updateFollowingStatus);
    _isPinned = widget.post.isPinned;
    _isPostMine = widget.post.creator.userID == _myUserId;

    _checkExistingEmotes();
  }

  void _updateFollowingStatus() {
    if (!mounted) return;

    final myFollowees = _sessionService.stateListenable.value?.followees ?? [];
    final isFollowing = myFollowees.any(
      (u) => u.userID == widget.post.creator.userID,
    );

    setState(() {
      _amIFollowingPostCreator = isFollowing;
    });
  }

  // Parent widget güncellenirse (örneğin liste yenilenirse) state'i senkronize et
  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.isPinned != oldWidget.post.isPinned) {
      _isPinned = widget.post.isPinned;
    }
  }

  Future<void> _checkExistingEmotes() async {
    if (_myUserId.isEmpty) return;

    final results = await Future.wait([
      _postRepository.isUserEmotedPost(
        widget.post.id,
        _myUserId,
        EmoteEnum.heart,
      ),
      _postRepository.isUserEmotedPost(
        widget.post.id,
        _myUserId,
        EmoteEnum.clap,
      ),
      _postRepository.isUserEmotedPost(
        widget.post.id,
        _myUserId,
        EmoteEnum.egg,
      ),
    ]);

    if (mounted) {
      setState(() {
        _isLikedByMe = results[0];
        _isClappedByMe = results[1];
        _isEggedByMe = results[2];
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _sessionService.stateListenable.removeListener(_updateFollowingStatus);
    super.dispose();
  }

  Future<void> _handleEmoteTap(EmoteEnum emote) async {
    if (_myUserId.isEmpty) return;

    bool isSelectedCurrent;
    int previousCount;
    bool previousState;

    switch (emote) {
      case EmoteEnum.heart:
        isSelectedCurrent = _isLikedByMe;
        previousCount = _likeCount;
        previousState = _isLikedByMe;
      case EmoteEnum.clap:
        isSelectedCurrent = _isClappedByMe;
        previousCount = _clapCount;
        previousState = _isClappedByMe;
      case EmoteEnum.egg:
        isSelectedCurrent = _isEggedByMe;
        previousCount = _eggCount;
        previousState = _isEggedByMe;
    }

    setState(() {
      if (emote == EmoteEnum.heart) {
        if (_isLikedByMe) {
          _likeCount--;
          _isLikedByMe = false;
        } else {
          _likeCount++;
          _isLikedByMe = true;
        }
      } else if (emote == EmoteEnum.clap) {
        if (_isClappedByMe) {
          _clapCount--;
          _isClappedByMe = false;
        } else {
          _clapCount++;
          _isClappedByMe = true;
        }
      } else if (emote == EmoteEnum.egg) {
        if (_isEggedByMe) {
          _eggCount--;
          _isEggedByMe = false;
        } else {
          _eggCount++;
          _isEggedByMe = true;
        }
      }
    });

    try {
      final analytics = getIt<AnalyticsService>();

      final amIFollowingPostCreator = _amIFollowingPostCreator;
      final amIFolloweeOfPostCreator =
          _sessionService.stateListenable.value?.followees.any(
            (u) => u.userID == widget.post.creator.userID,
          ) ??
          false;
      if (isSelectedCurrent) {
        await _postRepository.removeEmoteFromPost(
          widget.post.id,
          _myUserId,
          emote,
        );

        analytics.logRemoveEmote(
          RemoveEmoteAnalyticsConfig(
            postID: widget.post.id,
            value: emote,
            isFollower: amIFollowingPostCreator,
            isFollowee: amIFolloweeOfPostCreator,
          ),
        );
      } else {
        await _postRepository.addEmoteToPost(widget.post.id, _myUserId, emote);
        analytics.logSendEmote(
          SendEmoteAnalyticsConfig(
            postID: widget.post.id,
            value: emote,
            isFollower: amIFollowingPostCreator,
            isFollowee: amIFolloweeOfPostCreator,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          if (emote == EmoteEnum.heart) {
            _likeCount = previousCount;
            _isLikedByMe = previousState;
          } else if (emote == EmoteEnum.clap) {
            _clapCount = previousCount;
            _isClappedByMe = previousState;
          } else if (emote == EmoteEnum.egg) {
            _eggCount = previousCount;
            _isEggedByMe = previousState;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem başarısız: $e')),
        );
      }
    }
  }

  void _navigateToProfile() {
    final userId = widget.user?.userID;
    if (userId != null && userId.isNotEmpty) {
      context.push('/home/profile/$userId');
    }
  }

  // --- AKSİYON FONKSİYONLARI ---

  Future<void> _handleReportPost() async {
    Navigator.pop(context);
    setState(() => isVisible = false);

    final currentUser = _sessionService.currentUser;
    if (currentUser == null) return;

    try {
      await getIt<SecurityService>().sendReport(
        ReportData(
          reportedEntityId: widget.post.id,
          reportedEntityType: 'post',
          reportedUserId: widget.post.creator.userID,
          requestOwnerId: currentUser.userID,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bildiriniz alındı, içerik gizlendi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapor gönderilirken bir hata oluştu.')),
        );
      }
    }
  }

  Future<void> _handleBlockUser() async {
    Navigator.pop(context);
    setState(() => isVisible = false);

    final currentUser = _sessionService.currentUser;
    if (currentUser == null) return;

    try {
      await getIt<SecurityService>().blockUser(
        ReportData(
          reportedEntityId: widget.post.id,
          reportedEntityType: 'post',
          reportedUserId: widget.post.creator.userID,
          requestOwnerId: currentUser.userID,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı engellendi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Engelleme başarısız oldu.')),
        );
      }
    }
  }

  Future<void> _handleUnfollowUser() async {
    Navigator.pop(context);
    try {
      await getIt<UserRepository>().removeFollowee(
        _myUserId,
        widget.post.creator.userID,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Takip bırakıldı.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem başarısız.')),
        );
      }
    }
  }

  // --- PIN MANTIĞI ---
  Future<void> _togglePinStatus() async {
    final newStatus = !_isPinned;

    // 1. UI'ı hemen güncelle (Optimistic Update)
    setState(() {
      _isPinned = newStatus;
    });

    // 2. Üst katmana hemen haber ver
    widget.onPinToggle?.call(newStatus);

    try {
      final analytics = getIt<AnalyticsService>();

      if (newStatus) {
        await _postRepository.pinPost(widget.post.id, _myUserId);
        analytics.logPinPost(PinPostAnalyticsConfig(postID: widget.post.id));
      } else {
        await _postRepository.unpinPost(widget.post.id, _myUserId);
        analytics.logUnpinPost(
          UnpinPostAnalyticsConfig(postID: widget.post.id),
        );
      }
    } catch (e) {
      // 3. Hata olursa işlemi geri al
      if (mounted) {
        setState(() {
          _isPinned = !newStatus;
        });

        // Hata durumunda üst katmana eski durumu bildir
        widget.onPinToggle?.call(!newStatus);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem başarısız oldu.')),
        );
      }
    }
  }

  void _showOtherUserPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              if (_amIFollowingPostCreator)
                _buildOptionItem(
                  context,
                  icon: Icons.person_remove_outlined,
                  text: 'Takibi Bırak',
                  color: Colors.black,
                  onTap: _handleUnfollowUser,
                ),
              _buildOptionItem(
                context,
                icon: Icons.block_outlined,
                text: 'Engelle',
                color: const Color(0xFFFF3B30),
                onTap: _handleBlockUser,
              ),
              _buildOptionItem(
                context,
                icon: Icons.report_gmailerrorred_outlined,
                text: 'Şikayet Et',
                color: const Color(0xFFFF3B30),
                onTap: _handleReportPost,
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(width: 16.w),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final caption = widget.post.caption;
    final mediaUrls = widget.post.imageUrls ?? [];
    final tags = widget.post.hobbies.map((h) => h.name).toList();

    final username = widget.user?.username ?? 'Buluşalım Kullanıcısı';
    final userprofileImageUrl =
        widget.user?.profileImageUrl ?? FileService.defaultProfileImageUrl();

    final staticLocationName =
        widget.post.displayAddress ?? 'Konum Bilgisi Yok';

    final participantAvatars = widget.post.participants
        .take(3)
        .map((p) => p.profileImageUrl)
        .toList();
    final defaultImageUrl = FileService.defaultProfileImageUrl();

    final effectiveMediaUrls = mediaUrls.isNotEmpty
        ? mediaUrls
        : [defaultImageUrl];

    return Center(
      child: Container(
        width: 361.w,
        margin: EdgeInsets.only(bottom: 24.h, top: 12.h),
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              context,
              profileImageUrl: userprofileImageUrl,
              username: username,
              location: staticLocationName,
            ),
            SizedBox(height: 12.h),
            _buildContent(
              context,
              mediaUrls: effectiveMediaUrls,
              likedByAvatars: participantAvatars,
            ),
            if (effectiveMediaUrls.length > 1) ...[
              SizedBox(height: 10.h),
              Center(child: _buildPageIndicator(effectiveMediaUrls.length)),
            ],
            SizedBox(height: 12.h),
            _buildFooter(context, caption: caption, tags: tags),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required String profileImageUrl,
    required String username,
    required String location,
  }) {
    final theme = Theme.of(context);
    final isPostMine = widget.post.creator.userID == _myUserId;
    final hasprofileImageUrl =
        profileImageUrl.isNotEmpty && profileImageUrl.startsWith('http');

    return Row(
      children: [
        GestureDetector(
          onTap: _navigateToProfile,
          child: CircleAvatar(
            radius: 20.r,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: hasprofileImageUrl
                ? CachedNetworkImageProvider(fixEmulatorUrl(profileImageUrl))
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
                onTap: _navigateToProfile,
                child: Text(
                  username,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _kTextMainColor,
                  ),
                ),
              ),
              Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12,
                  color: _kTextMainColor,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(Icons.more_vert, color: theme.colorScheme.secondary),
          onPressed: () {
            if (isPostMine) {
              showModalBottomSheet<void>(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (sheetContext) => CustomActionBottomSheet(
                  options: [
                    if (_isPinned)
                      BottomSheetOption(
                        icon: Icons.push_pin,
                        text: 'Sabitlemeyi Kaldır',
                        onTap: () {
                          sheetContext.pop();
                          _togglePinStatus();
                        },
                      )
                    else
                      BottomSheetOption(
                        icon: Icons.push_pin_outlined,
                        text: 'Gönderiyi Profile Sabitle',
                        onTap: () {
                          sheetContext.pop();
                          _togglePinStatus();
                        },
                      ),
                    /* BottomSheetOption(
                      icon: Icons.share_outlined,
                      text: 'Gönderiyi Paylaş',
                      onTap: () {
                        sheetContext.pop();
                      },
                    ),*/
                    BottomSheetOption(
                      icon: Icons.delete_outline,
                      text: 'Gönderiyi Sil',
                      isDestructive: true,
                      onTap: () async {
                        sheetContext.pop();
                        if (mounted) {
                          setState(() {
                            isVisible = false;
                          });
                        }
                        await getIt<PostRepository>().deletePost(
                          widget.post.id,
                        );

                        widget.onPostDeleted?.call();
                      },
                    ),
                  ],
                ),
              );
            } else {
              _showOtherUserPostOptions(context);
            }
          },
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required List<String> mediaUrls,
    required List<String> likedByAvatars,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: SizedBox(
            width: 361.w,
            height: 361.w,
            child: PageView.builder(
              controller: _pageController,
              itemCount: mediaUrls.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final currentMedia = mediaUrls[index];
                final isNetworkMedia = currentMedia.startsWith('http');

                return isNetworkMedia
                    ? CachedNetworkImage(
                        fadeInDuration: Duration.zero,
                        imageUrl: fixEmulatorUrl(currentMedia),
                        fit: BoxFit.cover,
                        errorWidget: (context, error, stackTrace) =>
                            Image.asset(
                              FileService.defaultProfileImageUrl(),
                              fit: BoxFit.cover,
                            ),
                      )
                    : Image.asset(
                        currentMedia, // Asset yolu (FileService.defaultProfileImageUrl() gibi)
                        fit: BoxFit.cover,
                      );
              },
            ),
          ),
        ),
        Positioned(
          bottom: 12.h,
          left: 12.w,
          right: 12.w,
          child: _buildInteractionsOverlay(
            context,
            likedByAvatars: likedByAvatars,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionsOverlay(
    BuildContext context, {
    required List<String> likedByAvatars,
  }) {
    return Container(
      height: 44.h,
      padding: EdgeInsets.symmetric(horizontal: 0.w),
      child: Row(
        children: [
          // 1. Kalp
          EmojiChip(
            emoji: '❤️',
            text: '$_likeCount',
            color: Colors.red,
            isSelected: _isLikedByMe,
            onTap: () => _handleEmoteTap(EmoteEnum.heart),
          ),

          SizedBox(width: 12.w),

          EmojiChip(
            emoji: '👏',
            text: '$_clapCount',
            color: Colors.amber,
            isSelected: _isClappedByMe,
            onTap: () => _handleEmoteTap(EmoteEnum.clap),
          ),

          SizedBox(width: 12.w),

          // 3. Yumurta
          EmojiChip(
            emoji: '🥚',
            text: '$_eggCount',
            color: Colors.white,
            isSelected: _isEggedByMe,
            onTap: () => _handleEmoteTap(EmoteEnum.egg),
          ),
          const Spacer(),
          SmallStackedAvatars(
            profileImageUrls: likedByAvatars,
            size: 28.r,
            overlap: 10.r,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int pageCount) {
    final activeColor = Theme.of(context).colorScheme.secondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(pageCount, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 6.w,
          height: 6.w,
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? activeColor
                : _kInactiveIndicatorColor,
          ),
        );
      }),
    );
  }

  Widget _buildFooter(
    BuildContext context, {
    required String caption,
    required List<String> tags,
  }) {
    const timeStyle = TextStyle(
      fontFamily: 'SF Pro Display',
      fontSize: 12,
      color: _kTextGreyColor,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 4.h, 0, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    caption,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SF Pro Display',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 16.w),
                CountdownTimer(
                  targetTime: widget.post.createdAt ?? DateTime.now(),
                  isEvent: false,
                  style: timeStyle,
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: tags
                  .take(3)
                  .map(
                    (tagLabel) => Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: ContentTagChip(
                        label: tagLabel,
                        icon: Icons.tag,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
