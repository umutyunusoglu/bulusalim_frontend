import 'package:bulusalim/components/countdown_timer.dart';
import 'package:bulusalim/core/constants/constant.dart';
import 'package:bulusalim/core/utils/types/enums/emote_enum.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:bulusalim/domain/feed/post/post_entity.dart';
import 'package:bulusalim/screens/home/post%20components/content_tag_chip.dart';
import 'package:bulusalim/screens/home/post%20components/emoji_chip.dart'; // InteractionChip
import 'package:bulusalim/screens/home/post%20components/small_stacked_avatars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    required this.post,
    required this.user,
    super.key,
  });
  final PostEntity post;
  final UserEntity? user;

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

  @override
  Widget build(BuildContext context) {
    /// 1. DİNAMİK VERİLER
    final String caption = widget.post.title;
    final List<String> mediaUrls = widget.post.imageUrls ?? [];
    final List<String> tags = widget.post.hobbies.map((h) => h.name).toList();

    final int likeCount = widget.post.emoteCounts[EmoteEnum.heart] ?? 0;
    final int clapCount = widget.post.emoteCounts[EmoteEnum.clap] ?? 0;
    final int eggCount = widget.post.emoteCounts[EmoteEnum.egg] ?? 0;

    final String username = widget.user?.username ?? 'Buluşalım Kullanıcısı';
    final String userAvatarUrl =
        widget.user?.profileImageUrl ??
        'https://picsum.photos/seed/avatar_default/100/100';

    /// 2. STATİK VERİLER
    const String staticLocationName = 'Blackfish Cafe, Kızılay, Çankaya';
    final List<String> staticLikedByAvatars = [
      'https://picsum.photos/seed/avatar2/100/100',
      'https://picsum.photos/seed/avatar3/100/100',
      'https://picsum.photos/seed/avatar4/100/100',
    ];
    const String defaultImageUrl = 'https://picsum.photos/seed/cafe/600/800';

    final List<String> effectiveMediaUrls = mediaUrls.isNotEmpty
        ? mediaUrls
        : [defaultImageUrl];

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 16.h, left: 16.w, right: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Kart Başlığı (HEADER) - Ortalanmış ve Kısıtlanmış
          Center(
            child: SizedBox(
              child: _buildHeader(
                context,
                avatarUrl: userAvatarUrl,
                username: username,
                location: staticLocationName,
              ),
            ),
          ),

          // 2. İçerik (RESİM) - Ortalanmış ve Kısıtlanmış
          Center(
            child: _buildContent(
              context,
              mediaUrls: effectiveMediaUrls,
              likeCount: likeCount,
              clapCount: clapCount,
              eggCount: eggCount,
              likedByAvatars: staticLikedByAvatars,
            ),
          ),

          // --- BOŞLUK (Bitişiklik Sorununun Çözümü) ---
          SizedBox(height: 10.h),

          if (effectiveMediaUrls.length > 1) ...[
            Center(
              child: _buildPageIndicator(effectiveMediaUrls.length),
            ),
          ],

          // 3. Alt Kısım (FOOTER) - Ortalanmış ve Kısıtlanmış
          Center(
            child: SizedBox(
              child: _buildFooter(
                context,
                caption: caption,
                tags: tags,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Kart Başlığı
  Widget _buildHeader(
    BuildContext context, {
    required String avatarUrl,
    required String username,
    required String location,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
      leading: CircleAvatar(
        radius: 20.r,
        backgroundImage: NetworkImage(avatarUrl),
      ),
      title: Text(
        username,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(location),
      trailing: IconButton(
        icon: const Icon(Icons.share_outlined),
        onPressed: () {
          /* Paylaşma fonksiyonu */
        },
      ),
    );
  }

  // 2. İçerik (Kaydırılabilir Resimler + Overlay)
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
        // Kaydırılabilir Resimler
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: SizedBox(
            height: 361.h,
            width: 361.w,
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
                );
              },
            ),
          ),
        ),

        // Resim Üzerindeki Overlay (Etkileşimler)
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

  // 2a. Etkileşim Overlay'i
  Widget _buildInteractionsOverlay(
    BuildContext context, {
    required int likeCount,
    required int clapCount,
    required int eggCount,
    required List<String> likedByAvatars,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(35.r),
      ),
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

  // 2b. Sayfa Gösterge Noktaları
  Widget _buildPageIndicator(int pageCount) {
    return Padding(
      padding: EdgeInsets.all(4.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(pageCount, (index) {
          return Container(
            width: 5.w,
            height: 5.h,
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == index
                  ? kButtonBackgroundColor
                  : Colors.grey.shade400,
            ),
          );
        }),
      ),
    );
  }

  // 3. Alt Kısım (Caption, Zaman ve Etiketler)
  Widget _buildFooter(
    BuildContext context, {
    required String caption,
    required List<String> tags,
  }) {
    // Geri sayım için stil (PostCard'a özel gri renk)
    final timeStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.grey.shade600,
    );

    // içeriği 12.w ile hizalıyoruz.
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
                  targetTime: widget.post.createdAt,
                  style: timeStyle,
                ),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // Etiketler
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: tags
                  .take(3)
                  .map(
                    (tagLabel) => ContentTagChip(
                      label: tagLabel,
                      icon: tagLabel.toLowerCase().contains('kahve')
                          ? Icons.coffee_outlined
                          : Icons.chat_bubble_outline,
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
// import 'package:bulusalim/components/countdown_timer.dart';
// import 'package:bulusalim/core/constants/constant.dart';
// import 'package:bulusalim/core/utils/types/enums/emote_enum.dart';
// import 'package:bulusalim/domain/entities/user/user_entity.dart';
// import 'package:bulusalim/domain/feed/post/post_entity.dart';
// import 'package:bulusalim/screens/home/post%20components/content_tag_chip.dart';
// import 'package:bulusalim/screens/home/post%20components/emoji_chip.dart';
// import 'package:bulusalim/screens/home/post%20components/small_stacked_avatars.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class PostCard extends StatefulWidget {
//   const PostCard({
//     super.key,
//     required this.post,
//     required this.user,
//   });
//   final PostEntity post;
//   final UserEntity? user;

//   @override
//   State<PostCard> createState() => _PostCardState();
// }

// class _PostCardState extends State<PostCard> {
//   final PageController _pageController = PageController();
//   int _currentPage = 0;

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     /// 1. DİNAMİK VERİLER
//     final String caption = widget.post.title;
//     final List<String> mediaUrls = widget.post.imageUrls ?? [];
//     final List<String> tags = widget.post.hobbies.map((h) => h.name).toList();

//     final int likeCount = widget.post.emoteCounts[EmoteEnum.heart] ?? 0;
//     final int clapCount = widget.post.emoteCounts[EmoteEnum.clap] ?? 0;
//     final int eggCount = widget.post.emoteCounts[EmoteEnum.egg] ?? 0;

//     final String username = widget.user?.username ?? 'Buluşalım Kullanıcısı';
//     final String userAvatarUrl =
//         widget.user?.profileImageUrl ??
//         'https://picsum.photos/seed/avatar_default/100/100';

//     /// 2. STATİK VERİLER
//     const String staticLocationName = 'Blackfish Cafe, Kızılay, Çankaya';
//     final List<String> staticLikedByAvatars = [
//       'https://picsum.photos/seed/avatar2/100/100',
//       'https://picsum.photos/seed/avatar3/100/100',
//       'https://picsum.photos/seed/avatar4/100/100', // 3. avatar
//     ];
//     const String defaultImageUrl = 'https://picsum.photos/seed/cafe/600/800';

//     final List<String> effectiveMediaUrls = mediaUrls.isNotEmpty
//         ? mediaUrls
//         : [defaultImageUrl];

//     return Card(
//       elevation: 2,
//       margin: EdgeInsets.only(bottom: 16.h),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildHeader(
//             context,
//             avatarUrl: userAvatarUrl,
//             username: username,
//             location: staticLocationName,
//           ),
//           Center(
//             child: _buildContent(
//               context,
//               mediaUrls: effectiveMediaUrls,
//               likeCount: likeCount,
//               clapCount: clapCount,
//               eggCount: eggCount,
//               likedByAvatars: staticLikedByAvatars,
//             ),
//           ),
//           if (effectiveMediaUrls.length > 1) ...[
//             SizedBox(height: 8.h),
//             Center(
//               child: _buildPageIndicator(effectiveMediaUrls.length),
//             ),
//           ],

//           _buildFooter(
//             context,
//             caption: caption,
//             tags: tags,
//           ),
//         ],
//       ),
//     );
//   }

//   // 1. Kart Başlığı
//   Widget _buildHeader(
//     BuildContext context, {
//     required String avatarUrl,
//     required String username,
//     required String location,
//   }) {
//     return ListTile(
//       leading: CircleAvatar(
//         radius: 20.r,
//         backgroundImage: NetworkImage(avatarUrl),
//       ),
//       title: Text(
//         username,
//         style: const TextStyle(fontWeight: FontWeight.bold),
//       ),
//       subtitle: Text(location),
//       trailing: IconButton(
//         icon: const Icon(Icons.share_outlined),
//         onPressed: () {
//           /* Paylaşma fonksiyonu */
//         },
//       ),
//     );
//   }

//   // 2. İçerik (Kaydırılabilir Resimler + Overlay)
//   Widget _buildContent(
//     BuildContext context, {
//     required List<String> mediaUrls,
//     required int likeCount,
//     required int clapCount,
//     required int eggCount,
//     required List<String> likedByAvatars,
//   }) {
//     return Stack(
//       children: [
//         ClipRRect(
//           borderRadius: BorderRadius.circular(12.r),
//           child: SizedBox(
//             height: 361.h, // Yükseklik
//             width: 361.w, // Genişlik (Ortalamak için)
//             child: PageView.builder(
//               controller: _pageController,
//               itemCount: mediaUrls.length,
//               onPageChanged: (index) {
//                 setState(() {
//                   _currentPage = index;
//                 });
//               },
//               itemBuilder: (context, index) {
//                 return Image.network(
//                   mediaUrls[index],
//                   fit: BoxFit.cover,
//                 );
//               },
//             ),
//           ),
//         ),
//         Positioned(
//           bottom: 12.h,
//           left: 12.w,
//           right: 12.w,
//           child: _buildInteractionsOverlay(
//             context,
//             likeCount: likeCount,
//             clapCount: clapCount,
//             eggCount: eggCount,
//             likedByAvatars: likedByAvatars,
//           ),
//         ),
//       ],
//     );
//   }

//   // 2a. Etkileşim Overlay'i
//   Widget _buildInteractionsOverlay(
//     BuildContext context, {
//     required int likeCount,
//     required int clapCount,
//     required int eggCount,
//     required List<String> likedByAvatars,
//   }) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
//       decoration: BoxDecoration(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(35.r),
//       ),
//       child: Row(
//         children: [
//           EmojiChip(
//             icon: Icons.favorite,
//             text: '$likeCount',
//             color: Colors.red,
//           ),
//           SizedBox(width: 12.w),
//           EmojiChip(
//             icon: Icons.chat_rounded,
//             text: '$clapCount',
//             color: Colors.amber,
//           ),
//           SizedBox(width: 12.w),
//           EmojiChip(
//             icon: Icons.egg,
//             text: '$eggCount',
//             color: Colors.white,
//           ),
//           const Spacer(),
//           SmallStackedAvatars(
//             avatarUrls: likedByAvatars,
//             size: 28.r,
//             overlap: 10.r,
//           ),
//         ],
//       ),
//     );
//   }

//   // 2b. Sayfa Gösterge Noktaları
//   Widget _buildPageIndicator(int pageCount) {
//     return Padding(
//       padding: EdgeInsets.all(4.r),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         mainAxisSize: MainAxisSize.min,
//         children: List.generate(pageCount, (index) {
//           return Container(
//             width: 5.w,
//             height: 5.h,
//             margin: EdgeInsets.symmetric(horizontal: 4.w),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: _currentPage == index
//                   ? kButtonBackgroundColor
//                   : Colors.grey.shade400,
//             ),
//           );
//         }),
//       ),
//     );
//   }

//   // 3. Alt Kısım (Caption, Zaman ve Etiketler)
//   Widget _buildFooter(
//     BuildContext context, {
//     required String caption,
//     required List<String> tags,
//   }) {
//     // Geri sayım için stil (PostCard'a özel gri renk)
//     final timeStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
//       color: Colors.grey.shade600,
//     );

//     return Padding(
//       padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 12.h),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Caption
//               Expanded(
//                 child: Text(
//                   caption,
//                   style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               SizedBox(width: 16.w),

//               // Zaman (Geri sayım sayacı)
//               CountdownTimer(
//                 targetTime: widget.post.createdAt, // Post'un tarihini ver
//                 style: timeStyle, // PostCard'a uygun gri stili ver
//               ),
//             ],
//           ),
//           SizedBox(height: 8.h),
//           // Etiketler
//           Row(
//             children: tags
//                 .take(3)
//                 .map(
//                   (tagLabel) => ContentTagChip(
//                     label: tagLabel,
//                     icon: tagLabel.toLowerCase().contains('kahve')
//                         ? Icons.coffee_outlined
//                         : Icons.chat_bubble_outline,
//                   ),
//                 )
//                 .toList(),
//           ),
//         ],
//       ),
//     );
//   }
// }
