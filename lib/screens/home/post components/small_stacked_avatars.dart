import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 3'lü Küçük Avatar Grubu (Post Card Beğeniler için)
class SmallStackedAvatars extends StatelessWidget {
  const SmallStackedAvatars({
    required this.avatarUrls,
    super.key,
    this.size = 28,
    this.overlap = 10,
  });

  final List<String> avatarUrls;
  final double size;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final items = avatarUrls.take(3).toList();

    // Toplam genişliği hesapla
    // (Eleman sayısı * (Boyut - Örtüşme)) + Son elemanın örtüşme payı
    final width = (items.length * (size - overlap)) + overlap;

    return SizedBox(
      height: size,
      width: width,
      child: Stack(
        // .reversed ekledik: Böylece ilk eleman (soldaki) en son çizilir ve en üstte görünür.
        children: List.generate(items.length, (index) {
          return Positioned(
            left: index * (size - overlap),
            child: CircleAvatar(
              radius: size / 2,
              backgroundColor: Colors.white, // Beyaz çerçeve efekti
              child: CircleAvatar(
                radius: (size / 2) - 2.r, // Çerçeve kalınlığı (2.r)
                backgroundImage: NetworkImage(items[index]),
                backgroundColor: Colors.grey.shade300,
                onBackgroundImageError: (_, __) {},
              ),
            ),
          );
        }).reversed.toList(),
      ),
    );
  }
}
