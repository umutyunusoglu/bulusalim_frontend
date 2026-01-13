import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/post_card.dart';
import 'package:bulusalim/core/utils/debug/android_image_url_fixer.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
import 'package:bulusalim/domain/entities/user/pinned_post_entity.dart';
import 'package:bulusalim/domain/repositories/post_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfilePostFeedPage extends StatefulWidget {
  const ProfilePostFeedPage({
    required this.posts,
    required this.initialIndex,
    super.key,
  });

  final List<UserPostEntity> posts;
  final int initialIndex;

  @override
  State<ProfilePostFeedPage> createState() => _ProfilePostFeedPageState();
}

class _ProfilePostFeedPageState extends State<ProfilePostFeedPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final double initialOffset = widget.initialIndex * 580.h;

    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF9FAFB,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Gönderiler",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Urbanist',
          ),
        ),
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        itemCount: widget.posts.length,
        itemBuilder: (context, index) {
          final pinnedPost = widget.posts[index];
          return _PostLoaderItem(pinnedPost: pinnedPost);
        },
      ),
    );
  }
}

class _PostLoaderItem extends StatefulWidget {
  const _PostLoaderItem({required this.pinnedPost});

  final UserPostEntity pinnedPost;

  @override
  State<_PostLoaderItem> createState() => _PostLoaderItemState();
}

class _PostLoaderItemState extends State<_PostLoaderItem> {
  bool _isLoading = true;
  PostEntity? _fullPost;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFullPost();
  }

  Future<void> _fetchFullPost() async {
    try {
      final postRepo = getIt<PostRepository>();
      final post = await postRepo.getPostById(widget.pinnedPost.postID);

      if (mounted) {
        setState(() {
          _fullPost = post;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gönderi yüklenemedi.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Yükleniyor Durumu (Skeleton benzeri yapı)
    if (_isLoading) {
      return Container(
        height: 400.h, // Yüklenirken alan kaplaması için
        margin: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  image: DecorationImage(
                    // Yüklenirken bulanık şekilde küçük resmi göster
                    image: NetworkImage(
                      fixEmulatorUrl(widget.pinnedPost.imageUrls.first),
                    ),
                    fit: BoxFit.cover,
                    opacity: 0.5,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              const CircularProgressIndicator.adaptive(),
            ],
          ),
        ),
      );
    }

    // 2. Hata Durumu
    if (_errorMessage != null || _fullPost == null) {
      return SizedBox(
        height: 100.h,
        child: Center(child: Text(_errorMessage ?? "Veri bulunamadı")),
      );
    }

    // 3. Başarılı Durum -> PostCard
    return PostCard(
      post: _fullPost!,
      user: _fullPost!.creator,
    );
  }
}
