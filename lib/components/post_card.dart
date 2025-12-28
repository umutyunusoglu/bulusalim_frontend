import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/countdown_timer.dart';
import 'package:bulusalim/core/utils/debug/android_image_url_fixer.dart';
import 'package:bulusalim/core/utils/types/enums/emote_enum.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
import 'package:bulusalim/domain/repositories/post_repository.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:bulusalim/screens/home/post%20components/content_tag_chip.dart';
import 'package:bulusalim/screens/home/post%20components/emoji_chip.dart';
import 'package:bulusalim/screens/home/post%20components/small_stacked_avatars.dart';
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
  final PostParticipantEntity? user;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // --- STATE DEĞİŞKENLERİ ---
  // Sayılar değişeceği için bunları state'te tutuyoruz
  late int _likeCount;
  late int _clapCount;
  late int _eggCount;

  // Kullanıcının seçim durumları
  bool _isLikedByMe = false;
  bool _isClappedByMe = false;
  bool _isEggedByMe = false;

  // Servisler
  late final PostRepository _postRepository;
  late final SessionService _sessionService;
  late final String _myUserId;

  @override
  void initState() {
    super.initState();
    _postRepository = getIt<PostRepository>();
    _sessionService = getIt<SessionService>();
    _myUserId = _sessionService.currentUser?.userID ?? '';

    // 1. Sayıları PostEntity'den başlat
    _likeCount = widget.post.emoteCounts[EmoteEnum.heart] ?? 0;
    _clapCount = widget.post.emoteCounts[EmoteEnum.clap] ?? 0;
    _eggCount = widget.post.emoteCounts[EmoteEnum.egg] ?? 0;

    // 2. Kullanıcı daha önce beğenmiş mi kontrol et
    _checkExistingEmotes();
  }

  /// Kullanıcının bu post'a attığı eski reaksiyonları kontrol eder
  Future<void> _checkExistingEmotes() async {
    if (_myUserId.isEmpty) return;

    // Performans notu: İdealde bu bilgi PostEntity içinde 'myReaction: ["heart"]' gibi gelmelidir.
    // Şimdilik ayrı sorgularla yapıyoruz:

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

  // --- LOGIC: TIKLAMA YÖNETİMİ ---
  Future<void> _handleEmoteTap(EmoteEnum emote) async {
    if (_myUserId.isEmpty) return; // Login olmamışsa işlem yapma

    // Hangi değişkenleri değiştireceğimizi belirleyelim
    bool isSelectedCurrent;

    // Geçici değişkenler (Rollback için)
    int previousCount;
    bool previousState;

    switch (emote) {
      case EmoteEnum.heart:
        isSelectedCurrent = _isLikedByMe;
        previousCount = _likeCount;
        previousState = _isLikedByMe;
        break;
      case EmoteEnum.clap:
        isSelectedCurrent = _isClappedByMe;
        previousCount = _clapCount;
        previousState = _isClappedByMe;
        break;
      case EmoteEnum.egg:
        isSelectedCurrent = _isEggedByMe;
        previousCount = _eggCount;
        previousState = _isEggedByMe;
        break;
    }

    // 1. Optimistic Update (Ekranı hemen güncelle)
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

    // 2. API İsteği
    try {
      if (isSelectedCurrent) {
        // Zaten seçiliydi, kaldırmak istiyor
        await _postRepository.removeEmoteFromPost(
          widget.post.id,
          _myUserId,
          emote,
        );
      } else {
        // Seçili değildi, eklemek istiyor
        await _postRepository.addEmoteToPost(
          widget.post.id,
          _myUserId,
          emote,
        );
      }
    } catch (e) {
      // 3. Hata olursa geri al (Rollback)
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
          SnackBar(content: Text("İşlem başarısız: $e")),
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

  @override
  Widget build(BuildContext context) {
    // Dynamic Data
    final caption = widget.post.caption;
    final mediaUrls = widget.post.imageUrls ?? [];
    final tags = widget.post.hobbies.map((h) => h.name).toList();

    final username = widget.user?.username ?? 'Buluşalım Kullanıcısı';
    final userAvatarUrl =
        widget.user?.profileImageUrl ??
        'https://picsum.photos/seed/avatar_default/100/100';

    // Static Data (Örnek)
    const staticLocationName = 'Blackfish Cafe, Kızılay, Çankaya';
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
            // 1. Header
            _buildHeader(
              context,
              avatarUrl: userAvatarUrl,
              username: username,
              location: staticLocationName,
            ),

            SizedBox(height: 12.h),

            // 2. Content (Image/PageView)
            _buildContent(
              context,
              mediaUrls: effectiveMediaUrls,
              likedByAvatars: participantAvatars,
            ),

            // Page Indicator
            if (effectiveMediaUrls.length > 1) ...[
              SizedBox(height: 10.h),
              Center(
                child: _buildPageIndicator(effectiveMediaUrls.length),
              ),
            ],

            SizedBox(height: 12.h),

            // 3. Footer
            _buildFooter(
              context,
              caption: caption,
              tags: tags,
            ),
          ],
        ),
      ),
    );
  }

  // --- HEADER WIDGET ---
  Widget _buildHeader(
    BuildContext context, {
    required String avatarUrl,
    required String username,
    required String location,
  }) {
    final theme = Theme.of(context);
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
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 12,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(Icons.share_outlined, color: theme.colorScheme.secondary),
          onPressed: () {},
        ),
      ],
    );
  }

  // --- CONTENT WIDGET ---
  Widget _buildContent(
    BuildContext context, {
    required List<String> mediaUrls,
    required List<String> likedByAvatars,
  }) {
    // Burada likeCount vb. parametreleri kaldırdım çünkü artık state'ten okuyacağız
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

        // Interaction Overlay
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

  // --- INTERACTION OVERLAY (GÜNCELLENDİ) ---
  Widget _buildInteractionsOverlay(
    BuildContext context, {
    required List<String> likedByAvatars,
  }) {
    return Container(
      height: 44.h,
      padding: EdgeInsets.symmetric(horizontal: 0.w),
      child: Row(
        children: [
          // KALP
          EmojiChip(
            icon: Icons.favorite,
            text: '$_likeCount', // State değişkeni
            color: Colors.red,
            isSelected: _isLikedByMe, // State değişkeni
            onTap: () => _handleEmoteTap(EmoteEnum.heart), // Logic bağlantısı
          ),
          SizedBox(width: 12.w),

          // ALKIŞ/CHAT
          EmojiChip(
            icon: Icons.chat_rounded,
            text: '$_clapCount', // State değişkeni
            color: Colors.amber,
            isSelected: _isClappedByMe, // State değişkeni
            onTap: () => _handleEmoteTap(EmoteEnum.clap),
          ),
          SizedBox(width: 12.w),

          // YUMURTA
          EmojiChip(
            icon: Icons.egg,
            text: '$_eggCount', // State değişkeni
            color: Colors.white,
            isSelected: _isEggedByMe, // State değişkeni
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

  // --- PAGE INDICATOR ---
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
                : const Color(0xFFD9D9D9),
          ),
        );
      }),
    );
  }

  // --- FOOTER ---
  Widget _buildFooter(
    BuildContext context, {
    required String caption,
    required List<String> tags,
  }) {
    const timeStyle = TextStyle(
      fontFamily: 'Urbanist',
      fontSize: 12,
      color: Color(0xFF8E8E93),
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
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 16.w),
                CountdownTimer(
                  targetTime: widget.post.createdAt ?? DateTime.now(),
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
                        icon: tagLabel.toLowerCase().contains('kahve')
                            ? Icons.coffee_outlined
                            : Icons.chat_bubble_outline,
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
