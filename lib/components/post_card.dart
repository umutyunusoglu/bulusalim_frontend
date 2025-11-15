import 'package:flutter/material.dart';
import 'package:bulusalim/domain/entities/post/post_entity.dart';

class PostCard extends StatelessWidget {
  final PostEntity post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrls != null && post.imageUrls!.isNotEmpty)
            AspectRatio(
              aspectRatio: 1.0,
              child: Image.network(
                post.imageUrls!.first,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  print("!!! PostCard Fotoğraf Yükleme Hatası: $error");
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
              aspectRatio: 1.0,
              child: Center(
                child: Icon(Icons.photo, size: 100, color: Colors.grey),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              post.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
