import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/repositories/post_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class SenlikPage extends StatelessWidget {
  const SenlikPage({super.key});

  @override
  Widget build(BuildContext context) {
    final postRepository = GetIt.instance<PostRepository>();
    final logger = GetIt.instance<LoggingService>();

    return FutureBuilder(
      future: postRepository.getAllPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty || posts[0].imageUrls!.isEmpty) {
          return const Center(child: Text("No posts available"));
        }

        final postPhotoUrl = posts[0].imageUrls!.first;
        logger.debug(postPhotoUrl);

        return Center(
          child: Image.network(
            postPhotoUrl,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
