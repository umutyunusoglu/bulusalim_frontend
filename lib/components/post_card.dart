import 'package:bulusalim/components/bottomsheetoption.dart';
import 'package:bulusalim/components/countdown_timer.dart';
import 'package:bulusalim/core/utils/types/enums/emote_enum.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Profil Yönlendirme Fonksiyonu
  void _navigateToProfile() {
    final userId = widget.user?.userID;
    // Eğer kullanıcı ID'si varsa profil sayfasına git
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

    final likeCount = widget.post.emoteCounts[EmoteEnum.heart] ?? 0;
    final clapCount = widget.post.emoteCounts[EmoteEnum.clap] ?? 0;
    final eggCount = widget.post.emoteCounts[EmoteEnum.egg] ?? 0;

    final username = widget.user?.username ?? 'Buluşalım Kullanıcısı';
    final userAvatarUrl =
        widget.user?.profileImageUrl ??
        'https://picsum.photos/seed/avatar_default/100/100';

    // Static Data
    const staticLocationName = 'Blackfish Cafe, Kızılay, Çankaya';
    final staticLikedByAvatars = widget.post.participants
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
              likeCount: likeCount,
              clapCount: clapCount,
              eggCount: eggCount,
              likedByAvatars: staticLikedByAvatars,
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

  // 1. Header Widget
  Widget _buildHeader(
    BuildContext context, {
    required String avatarUrl,
    required String username,
    required String location,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Avatar hala tıklanabilir kalsın (Genelde beklenir)
        GestureDetector(
          onTap: _navigateToProfile,
          child: CircleAvatar(
            radius: 20.r,
            backgroundImage: NetworkImage(avatarUrl),
          ),
        ),
        SizedBox(width: 12.w),

        // İsim ve Konum Alanı
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SADECE İSİM TIKLANABİLİR
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

              // 2. KONUM ARTIK TIKLANAMAZ (Normal Text)
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
          icon: Icon(Icons.more_vert, color: theme.colorScheme.secondary),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => CustomActionBottomSheet(
                height: 201.h,
                options: [
                  BottomSheetOption(
                    icon: Icons.person_off_outlined,
                    text: "Buluşma Sahibini Takibi Bırak",
                    onTap: () {
                      context.pop();
                    },
                  ),
                  BottomSheetOption(
                    icon: Icons.share_outlined,
                    text: "Paylaş",
                    onTap: () {
                      context.pop();
                    },
                  ),
                  BottomSheetOption(
                    icon: Icons.report_gmailerrorred_outlined,
                    text: "Şikayet Et",
                    isDestructive: true,
                    onTap: () {
                      context.pop();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // 2. Content Widget
  Widget _buildContent(
    BuildContext context, {
    required List<String> mediaUrls,
    required int likeCount,
    required int clapCount,
    required int eggCount,
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
                  mediaUrls[index],
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
            likeCount: likeCount,
            clapCount: clapCount,
            eggCount: eggCount,
            likedByAvatars: likedByAvatars,
          ),
        ),
      ],
    );
  }

  // 2a. Interaction Overlay Widget
  Widget _buildInteractionsOverlay(
    BuildContext context, {
    required int likeCount,
    required int clapCount,
    required int eggCount,
    required List<String> likedByAvatars,
  }) {
    return Container(
      height: 44.h,
      padding: EdgeInsets.symmetric(horizontal: 0.w),
      child: Row(
        children: [
          EmojiChip(
            icon: Icons.favorite,
            text: '$likeCount',
            color: Colors.red,
          ),
          SizedBox(width: 12.w),
          EmojiChip(
            icon: Icons.chat_rounded,
            text: '$clapCount',
            color: Colors.amber,
          ),
          SizedBox(width: 12.w),
          EmojiChip(
            icon: Icons.egg,
            text: '$eggCount',
            color: Colors.white,
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

  // 2b. Page Indicator Widget
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

  // 3. Footer Widget
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
          // Row containing Caption and Timer
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
                // Corrected CountdownTimer placement
                CountdownTimer(
                  targetTime: widget.post.createdAt ?? DateTime.now(),
                  style: timeStyle,
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          // Tags Row
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
