import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StackedAvatars extends StatelessWidget {
  final List<String> avatarUrls;

  const StackedAvatars({
    required this.avatarUrls,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Boyutları tanımla
    final double firstAvatarSize = 42.r;
    final double otherAvatarSize = 33.r;

    // 2. Üst üste binme miktarını tanımla
    final double overlap = 16.r;

    final items = avatarUrls.take(3).toList();
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    List<Widget> avatarWidgets = [];
    double currentLeftPosition = 0;

    // 3. Avatarları ve pozisyonlarını hesapla
    for (int i = 0; i < items.length; i++) {
      final isFirst = (i == 0);
      final currentSize = isFirst ? firstAvatarSize : otherAvatarSize;

      avatarWidgets.add(
        Positioned(
          left: currentLeftPosition,
          bottom: 0,
          child: SizedBox(
            width: currentSize,
            height: currentSize,
            child: CircleAvatar(
              radius: (currentSize / 2),
              backgroundImage: NetworkImage(items[i]),
              backgroundColor: Colors.grey.shade300,
              onBackgroundImageError: (exception, stackTrace) {
                debugPrint('Avatar yüklenemedi: $exception');
              },
            ),
          ),
        ),
      );

      // Bir sonraki avatarın pozisyonunu hazırla
      if (isFirst) {
        currentLeftPosition += (firstAvatarSize - overlap);
      } else {
        currentLeftPosition += (otherAvatarSize - overlap);
      }
    }

    // 4. Toplam genişliği hesapla
    double totalWidth;
    if (items.length == 1) {
      totalWidth = firstAvatarSize;
    } else if (items.length == 2) {
      totalWidth = (firstAvatarSize - overlap) + otherAvatarSize;
    } else {
      totalWidth =
          (firstAvatarSize - overlap) +
          (otherAvatarSize - overlap) +
          otherAvatarSize;
    }

    return SizedBox(
      height: firstAvatarSize,
      width: totalWidth,
      // Stack içindeki öğeleri ters çeviriyoruz ki ilk sıradaki en üstte görünsün
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomLeft,
        children: avatarWidgets.reversed.toList(),
      ),
    );
  }
}
