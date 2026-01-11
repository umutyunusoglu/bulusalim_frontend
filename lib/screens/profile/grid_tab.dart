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
    final allPosts = [...activePosts, ...pinnedPosts];

    Navigator.push(
      context,
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
    final allPosts = [...activePosts, ...pinnedPosts];

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
      ),
      itemCount: allPosts.length,
      itemBuilder: (context, index) {
        final isActive = index < activePosts.length;
        final iconData = isActive ? Icons.access_time_filled : Icons.push_pin;
        final post = allPosts[index];

        return GestureDetector(
          // TIKLAMA OLAYI BURADA
          onTap: () => _openFeedPage(context, index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. FOTOĞRAF
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  image: DecorationImage(
                    image: NetworkImage(
                      fixEmulatorUrl(post.imageUrls.first),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 2. SAĞ ÜST İKON
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
    );
  }
}
