import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/presentation/shared/post_card/post_card.dart';
import 'package:outnest/domain/repositories/post_repository.dart';

// Replace these with your real imports
// import 'package:your_app/features/posts/data/post_repository.dart';
// import 'package:your_app/features/posts/domain/post.dart';
// import 'package:your_app/features/posts/presentation/widgets/post_card.dart';

class PostPreviewScreen extends StatefulWidget {
  final String postId;

  const PostPreviewScreen({
    super.key,
    required this.postId,
  });

  @override
  State<PostPreviewScreen> createState() => _PostPreviewScreenState();
}

class _PostPreviewScreenState extends State<PostPreviewScreen> {
  late Future<PostEntity?> _postFuture;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void didUpdateWidget(covariant PostPreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      _loadPost();
    }
  }

  void _loadPost() {
    final postRepository = getIt<PostRepository>();
    _postFuture = postRepository.getPostById(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: FutureBuilder<PostEntity?>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load post: ${snapshot.error}'),
            );
          }

          final post = snapshot.data;
          if (post == null) {
            return const Center(child: Text('Post not found'));
          }

          return SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PostCard(
                    post: post,
                    user: post.creator,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
