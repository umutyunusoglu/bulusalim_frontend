import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/bottomsheetoption.dart';
import 'package:outnest/components/countdown_timer.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/core/utils/types/enums/emote_enum.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/post_repository.dart';
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
    super.key,
  });
  final PostEntity post;
  final CompactUserEntity? user;

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

    _checkExistingEmotes();
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
      if (isSelectedCurrent) {
        await _postRepository.removeEmoteFromPost(
          widget.post.id,
          _myUserId,
          emote,
        );
      } else {
        await _postRepository.addEmoteToPost(widget.post.id, _myUserId, emote);
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

  // --- YENİ EKLENEN: BAŞKASININ PROFİLİ İÇİN MENÜ ---
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
              // Gri Çizgi (Drag Handle)
              Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),

              // 1. Takibi Bırak
              _buildOptionItem(
                context,
                icon: Icons.person_remove_outlined,
                text: 'Takibi Bırak',
                color: Colors.black,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Takibi bırakma servisi
                },
              ),

              // 2. Engelle (Kırmızı)
              _buildOptionItem(
                context,
                icon: Icons.block_outlined,
                text: 'Engelle',
                color: const Color(0xFFFF3B30),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Engelleme servisi
                },
              ),

              // 3. Şikayet Et (Kırmızı)
              _buildOptionItem(
                context,
                icon: Icons.report_gmailerrorred_outlined,
                text: 'Şikayet Et',
                color: const Color(0xFFFF3B30),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Şikayet servisi
                },
              ),

              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }

  // Menü Yardımcı Widget'ı
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
    final userAvatarUrl =
        widget.user?.profileImageUrl ??
        'https://picsum.photos/seed/avatar_default/100/100';

    final staticLocationName =
        widget.post.displayAddress ?? 'Konum Bilgisi Yok';
    final participantAvatars = widget.post.participants
        .take(3)
        .map((p) => p.profileImageUrl)
        .toList();
    const defaultImageUrl = 'https://picsum.photos/seed/cafe/600/800';

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
              avatarUrl: userAvatarUrl,
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
    required String avatarUrl,
    required String username,
    required String location,
  }) {
    final theme = Theme.of(context);
    final isPostMine = widget.post.creator.userID == _myUserId;
    final isPinned = widget.post.isPinned;

    return Row(
      children: [
        GestureDetector(
          onTap: _navigateToProfile,
          child: CircleAvatar(
            radius: 20.r,
            backgroundImage: NetworkImage(fixEmulatorUrl(avatarUrl)),
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
        // --- 3 NOKTA MENÜSÜ ---
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(Icons.more_vert, color: theme.colorScheme.secondary),
          onPressed: () {
            if (isPostMine) {
              // --- KENDİ GÖNDERİSİ İSE ESKİ MENÜ ---
              showModalBottomSheet<void>(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (sheetContext) => CustomActionBottomSheet(
                  options: [
                    if (isPinned)
                      BottomSheetOption(
                        icon: Icons.push_pin_outlined,
                        text: 'Sabitlemeyi Kaldır',
                        onTap: () async {
                          sheetContext.pop();
                        },
                      )
                    else
                      BottomSheetOption(
                        icon: Icons.push_pin,
                        text: 'Gönderiyi Profile Sabitle',
                        onTap: () async {
                          sheetContext.pop();
                        },
                      ),
                    BottomSheetOption(
                      icon: Icons.share_outlined,
                      text: 'Gönderiyi Paylaş',
                      onTap: () {
                        sheetContext.pop();
                      },
                    ),
                    BottomSheetOption(
                      icon: Icons.delete_outline,
                      text: 'Gönderiyi Sil',
                      isDestructive: true,
                      onTap: () async {
                        if (mounted) {
                          setState(() {
                            isVisible = false;
                          });
                        }
                        if (sheetContext.mounted) {
                          sheetContext.pop();
                        }
                      },
                    ),
                  ],
                ),
              );
            } else {
              // --- BAŞKASININ GÖNDERİSİ İSE YENİ TASARIM MENÜ ---
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
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.network(
                  fixEmulatorUrl(mediaUrls[index]),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.grey.shade200),
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
          EmojiChip(
            icon: Icons.favorite,
            text: '$_likeCount',
            color: Colors.red,
            isSelected: _isLikedByMe,
            onTap: () => _handleEmoteTap(EmoteEnum.heart),
          ),
          SizedBox(width: 12.w),
          EmojiChip(
            icon: Icons.chat_rounded,
            text: '$_clapCount',
            color: Colors.amber,
            isSelected: _isClappedByMe,
            onTap: () => _handleEmoteTap(EmoteEnum.clap),
          ),
          SizedBox(width: 12.w),
          EmojiChip(
            icon: Icons.egg,
            text: '$_eggCount',
            color: Colors.white,
            isSelected: _isEggedByMe,
            onTap: () => _handleEmoteTap(EmoteEnum.egg),
          ),
          const Spacer(),
          SmallStackedAvatars(
            avatarUrls: likedByAvatars,
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
