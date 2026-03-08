import 'package:cached_network_image/cached_network_image.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/user/pinned_post_entity.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/presentation/profile/view/components/dump_tab.dart';
import 'package:outnest/presentation/profile/view/components/empty_profile_screen.dart';
import 'package:outnest/presentation/profile/view/profile_feed_page.dart';
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
    if (totalPosts.isEmpty) {
      return EmptyProfileScreen(
        text: 'Profilini doldurmak için etkinliklere katıl. Anılarını paylaş!',
        icon: Icon(
          Icons.camera_alt,
          size: 48.sp,
          color: AppColors.tertiaryColor.withOpacity(0.7),
        ),
      );
    }
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

          final isNetwork = post.imageUrls.isNotEmpty;
          final imageUrl = isNetwork
              ? post.imageUrls.first
              : FileService.defaultProfileImageUrl(); // Fallback resmimiz (Asset)

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
                      // URL varsa CachedNetworkImageProvider + Fix, yoksa (asset ise) AssetImage
                      image: isNetwork
                          ? CachedNetworkImageProvider(fixEmulatorUrl(imageUrl))
                          : AssetImage(imageUrl) as ImageProvider,
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
