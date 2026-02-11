import 'package:cached_network_image/cached_network_image.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:flutter/material.dart';
import 'package:outnest/domain/services/file_service.dart';

class SmallStackedAvatars extends StatelessWidget {
  const SmallStackedAvatars({
    required this.avatarUrls,
    super.key,
    this.size = 28,
    this.overlap = 10,
    this.borderColor = Colors.white,
    this.borderWidth = 1.5,
  });

  final List<String> avatarUrls;
  final double size;
  final double overlap;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    // En fazla 3 avatar göster
    final items = avatarUrls.take(3).toList();

    // Toplam genişlik hesabı: (Adet * (Boyut - Örtüşme)) + Örtüşme
    // Örn: 3 resim, 24 boyut, 10 örtüşme -> (3 * 14) + 10 = 52 genişlik
    final width = (items.length * (size - overlap)) + overlap;

    return SizedBox(
      height: size,
      width: width,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: List.generate(items.length, (index) {
          final currentItem = items[index] ?? '';
          final isNetwork = currentItem.startsWith('http');

          return Positioned(
            left: index * (size - overlap),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
                image: DecorationImage(
                  image: isNetwork
                      ? CachedNetworkImageProvider(fixEmulatorUrl(currentItem))
                      : AssetImage(FileService.defaultProfileImageUrl())
                            as ImageProvider,
                  fit: BoxFit.cover,
                ),
                color: Colors.grey.shade300,
              ),
            ),
          );
        }),
      ),
    );
  }
}
