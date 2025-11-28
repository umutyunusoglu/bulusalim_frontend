import 'package:bulusalim/components/countdown_timer.dart';
import 'package:bulusalim/components/custom_bottom_sheet.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/core/utils/types/enums/emote_enum.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
import 'package:bulusalim/screens/home/post%20components/content_tag_chip.dart';
import 'package:bulusalim/screens/home/post%20components/emoji_chip.dart';
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
  final PostParticipantEntity? user;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // --- State Yönetimi ---
  // Resimler arasında geçiş yapmak için kullanılan kontrolcü
  final PageController _pageController = PageController();
  // Şu an hangi resimde olduğumuzu tutan değişken
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- Veri Hazırlığı ---
    // UI içerisinde kullanmak için Entity'den verileri ayıklıyoruz
    final caption = widget.post.caption;
    final mediaUrls = widget.post.imageUrls ?? [];
    final tags = widget.post.hobbies.map((h) => h.name).toList();

    // Etkileşim sayıları (Kalp, Alkış, Yumurta vb.)
    final likeCount = widget.post.emoteCounts[EmoteEnum.heart] ?? 0;
    final clapCount = widget.post.emoteCounts[EmoteEnum.clap] ?? 0;
    final eggCount = widget.post.emoteCounts[EmoteEnum.egg] ?? 0;

    // Kullanıcı bilgileri (Null kontrolü ile varsayılan değerler)
    final username = widget.user?.username ?? 'Buluşalım Kullanıcısı';
    final userAvatarUrl =
        widget.user?.profileImageUrl ??
        'https://picsum.photos/seed/avatar_default/100/100';

    // Statik veriler (İleride dinamik hale getirilebilir)
    const staticLocationName = 'Blackfish Cafe, Kızılay, Çankaya';
    final staticLikedByAvatars = widget.post.participants
        .take(3)
        .map((p) => p.profileImageUrl)
        .toList();
    const defaultImageUrl = 'https://picsum.photos/seed/cafe/600/800';

    // Eğer resim yoksa varsayılan resmi göster
    final effectiveMediaUrls = mediaUrls.isNotEmpty
        ? mediaUrls
        : [defaultImageUrl];

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 20.h, left: 16.w, right: 16.w, top: 20),
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

          // Sayfa Göstergesi (Sadece birden fazla resim varsa gösterilir)
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

  // --- Yardımcı Widget Metotları ---

  // Header oluşturucu: Avatar ve kullanıcı bilgilerini içerir
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

  // İçerik oluşturucu: Resimlerin olduğu PageView ve üzerindeki butonları içerir
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
        // Resim Kaydırıcı (Carousel)
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
        // Resmin üzerindeki etkileşim çipleri (Overlay)
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

  // Etkileşim katmanı: Kalp, yorum ikonları ve beğenenlerin avatarları
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
        color: Colors.transparent, // Arkaplan şeffaf
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
          // İç içe geçmiş küçük avatarlar
          SmallStackedAvatars(
            avatarUrls: likedByAvatars,
            size: 28.r,
            overlap: 10.r,
          ),
        ],
      ),
    );
  }

  // Sayfa indikatörü (Noktalar): Hangi resimde olduğumuzu gösterir
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
              // Aktif sayfa ise tema rengi, değilse gri
              color: _currentPage == index
                  ? AppColors.slateBlue
                  : Colors.grey.shade400,
            ),
          );
        }),
      ),
    );
  }

  // Footer oluşturucu: Başlık, geri sayım ve etiketler
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
          // Başlık ve Süre
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
                // Etkinlik için geri sayım bileşeni
                CountdownTimer(
                  targetTime: widget.post.createdAt,
                  style: timeStyle,
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          // Etiketler (Chips) - Kahve içeriyorsa farklı ikon
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
