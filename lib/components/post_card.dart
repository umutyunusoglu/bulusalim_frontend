import 'package:bulusalim/application/providers/get_It_init.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  const PostCard({required this.post, super.key});
  final PostEntity post;

  @override
  Widget build(BuildContext context) {
    final logger = getIt<LoggingService>();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrls != null && post.imageUrls!.isNotEmpty)
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                post.imageUrls!.first,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  logger.error('!!! PostCard Fotoğraf Yükleme Hatası: $error');
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.red,
                    ),
                  );
                },
              ),
            )
          else
            const AspectRatio(
              aspectRatio: 1,
              child: Center(
                child: Icon(Icons.photo, size: 100, color: Colors.grey),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              post.caption,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
