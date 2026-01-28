import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/user/pinned_post_entity.dart';
import 'package:outnest/screens/profile/profile_feed_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileGridTab extends StatelessWidget {
  const ProfileGridTab({
    required this.pinnedPosts,
    required this.activePosts,
    required this.onPinChanged, // Bu fonksiyonu Feed sayfasına taşıyacağız
    super.key,
  });

  final List<UserPostEntity> pinnedPosts;
  final List<UserPostEntity> activePosts;
  final void Function(String postId, bool isPinned)? onPinChanged;

  void _openFeedPage(BuildContext context, int index) {
    // 1. Sabitlenmiş Postları İşaretle (isPinned: true)
    final markedPinnedPosts = pinnedPosts.map((post) {
      return post.copyWith(isPinned: true);
    }).toList();

    // 2. Aktif Postları İşaretle (isPinned: false)
    final markedActivePosts = activePosts.map((post) {
      return post.copyWith(isPinned: false);
    }).toList();

    // 3. Listeleri birleştir (Sıralama Düzeltildi: Önce Pinned, Sonra Active)
    final allPosts = [...markedPinnedPosts, ...markedActivePosts];

    // Sayfayı Navbar'ın üzerinde aç (rootNavigator: true)
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ProfilePostFeedPage(
          posts: allPosts,
          initialIndex: index,
          // ÖNEMLİ: Callback fonksiyonunu detay sayfasına iletiyoruz
          onPinChanged: onPinChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sıralama Düzeltildi: Önce Pinned, Sonra Active
    final totalPosts = [...pinnedPosts, ...activePosts];
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
        ),
        itemCount: totalPosts.length,
        itemBuilder: (context, index) {
          // Index kontrolü düzeltildi:
          // Eğer index, pinned listesinin uzunluğundan küçükse o bir Pinned posttur.
          final isPinnedItem = index < pinnedPosts.length;

          final iconData = isPinnedItem
              ? Icons.push_pin
              : Icons.access_time_filled; // İsteğe bağlı ikon değişimi

          final post = totalPosts[index];

          // Güvenli resim URL'si
          final imageUrl = (post.imageUrls.isNotEmpty)
              ? post.imageUrls.first
              : 'https://picsum.photos/200'; // Fallback

          return GestureDetector(
            onTap: () => _openFeedPage(context, index),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. FOTOĞRAF
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    color: theme.colorScheme.surfaceContainerHighest,
                    image: DecorationImage(
                      image: NetworkImage(
                        fixEmulatorUrl(imageUrl),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // 2. SAĞ ÜST İKON (Pinned ise Pin ikonu, değilse saat vb.)
                Positioned(
                  top: 6.h,
                  right: 4.w,
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2), // Hafif arka plan
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: Colors.white,
                      size: 16.sp,
                      shadows: const [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
