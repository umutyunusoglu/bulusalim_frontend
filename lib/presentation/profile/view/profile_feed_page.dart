import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/repositories/post_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/presentation/shared/post_card/post_card.dart';

class ProfilePostFeedPage extends StatefulWidget {
  const ProfilePostFeedPage({
    required this.posts,
    required this.initialIndex,
    this.onPinChanged,
    super.key,
  });

  final List<PostEntity> posts;
  final int initialIndex;
  final void Function(String postId, bool isPinned)? onPinChanged;

  @override
  State<ProfilePostFeedPage> createState() => _ProfilePostFeedPageState();
}

class _ProfilePostFeedPageState extends State<ProfilePostFeedPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // Tahmini yükseklik üzerinden scroll
    final initialOffset = widget.initialIndex * 580.h;
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Symbols.reply, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Gönderiler',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Sf Pro Display',
          ),
        ),
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        itemCount: widget.posts.length,
        // ÖNEMLİ: addAutomaticKeepAlives: true varsayılandır ama listede durumu korumak önemlidir.
        itemBuilder: (context, index) {
          final pinnedPost = widget.posts[index];
          return _PostLoaderItem(
            // Key eklemek performans ve state karışıklığını önler
            key: ValueKey(pinnedPost.postID),
            pinnedPost: pinnedPost,
            onPinChanged: widget.onPinChanged,
          );
        },
      ),
    );
  }
}

class _PostLoaderItem extends StatefulWidget {
  const _PostLoaderItem({
    required this.pinnedPost,
    this.onPinChanged,
    super.key, // Key parametresini buraya da ekledik
  });

  final PostEntity pinnedPost;
  final void Function(String, bool)? onPinChanged;

  @override
  State<_PostLoaderItem> createState() => _PostLoaderItemState();
}

// AutomaticKeepAliveClientMixin: Scroll edince postun yeniden yüklenmesini engeller
class _PostLoaderItemState extends State<_PostLoaderItem>
    with AutomaticKeepAliveClientMixin {
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

      if (!mounted) return;

      if (post == null) {
        // Hata loglamasını BURADA yapıyoruz, build içinde değil.
        const msg = 'Post verisi null döndü (Veritabanında bulunamadı)';
        getIt<LoggingService>().error(
          'Post yükleme hatası ID: ${widget.pinnedPost.postID} -> $msg',
        );

        setState(() {
          _errorMessage = 'İçerik bulunamadı';
          _isLoading = false;
        });
      } else {
        setState(() {
          _fullPost = post.copyWith(isPinned: widget.pinnedPost.isPinned);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      // Exception loglamasını burada yapıyoruz
      getIt<LoggingService>().error('Post yükleme exception: $e');

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // KeepAlive için gerekli

    // 1. Yükleniyor Durumu
    if (_isLoading) {
      final hasImage = widget.pinnedPost.imageUrls.isNotEmpty;
      final imageUrl = hasImage
          ? widget.pinnedPost.imageUrls.first
          : FileService.defaultProfileImageUrl(); // Asset fallback

      return Container(
        height: 400.h,
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
                    // URL varsa CachedNetworkImageProvider, yoksa AssetImage kullan
                    image: hasImage
                        ? CachedNetworkImageProvider(fixEmulatorUrl(imageUrl))
                        : AssetImage(imageUrl) as ImageProvider,
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
      // BURADAKİ LOGLAMA KALDIRILDI.
      // Sadece UI gösteriyoruz.
      return SizedBox(
        height: 100.h,
        child: Center(
          child: Text(
            _errorMessage ?? 'Veri bulunamadı',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // 3. Başarılı Durum -> PostCard
    return PostCard(
      post: _fullPost!,
      user: _fullPost!.creator,
      onPinToggle: (isPinned) {
        setState(() {
          _fullPost = _fullPost!.copyWith(isPinned: isPinned);
        });
        widget.onPinChanged?.call(_fullPost!.id, isPinned);
      },
    );
  }

  @override
  bool get wantKeepAlive => true; // State'i koru
}
