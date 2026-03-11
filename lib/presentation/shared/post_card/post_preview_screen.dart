import 'package:flutter/material.dart';
import 'package:outnest/application/providers/get_it_init.dart';
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
  late final Future<PostEntity?> _postFuture;

  @override
  void initState() {
    super.initState();
    final postRepository = getIt<PostRepository>();
    _postFuture = postRepository.getPostById(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
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
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: PostCard(
                  post: post,
                  user: post.creator,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
