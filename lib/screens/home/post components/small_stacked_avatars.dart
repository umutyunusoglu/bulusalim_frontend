import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:flutter/material.dart';

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
        // Soldan sağa hizalama
        alignment: Alignment.centerLeft,
        children: List.generate(items.length, (index) {
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
                  image: NetworkImage(fixEmulatorUrl(items[index])),
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
