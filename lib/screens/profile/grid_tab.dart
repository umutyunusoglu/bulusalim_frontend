import 'package:bulusalim/core/utils/debug/android_image_url_fixer.dart';
import 'package:bulusalim/domain/entities/user/pinned_post_entity.dart';
import 'package:bulusalim/screens/profile/profile_feed_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileGridTab extends StatelessWidget {
  const ProfileGridTab({
    required this.pinnedPosts,
    required this.activePosts,
    super.key,
  });

  final List<UserPostEntity> pinnedPosts;
  final List<UserPostEntity> activePosts;

  void _openFeedPage(BuildContext context, int index) {
    // 1. Aktif Postları İşaretle (isPinned: false)
    final markedActivePosts = activePosts.map((post) {
      return post.copyWith(isPinned: false);
    }).toList();

    // 2. Sabitlenmiş Postları İşaretle (isPinned: true)
    final markedPinnedPosts = pinnedPosts.map((post) {
      return post.copyWith(isPinned: true);
    }).toList();

    // 3. Listeleri birleştir (Sıralama: Önce Active, Sonra Pinned)
    final allPosts = [...markedActivePosts, ...markedPinnedPosts];

    // Sayfayı Navbar'ın üzerinde aç (rootNavigator: true)
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ProfilePostFeedPage(
          posts: allPosts,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPosts = [...activePosts, ...pinnedPosts];
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
          final isPinnedItem = index >= activePosts.length;

          final iconData = isPinnedItem
              ? Icons.push_pin
              : Icons.access_time_filled;

          final post = totalPosts[index];

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
                        fixEmulatorUrl(post.imageUrls.first),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // 2. SAĞ ÜST İKON (Dinamik)
                Positioned(
                  top: 6.h,
                  right: 4.w,
                  child: Container(
                    padding: EdgeInsets.all(6.r),
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
