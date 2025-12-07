import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StackedAvatars extends StatelessWidget {
  final List<String> avatarUrls;

  const StackedAvatars({
    Key? key,
    required this.avatarUrls,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (avatarUrls.isEmpty) return const SizedBox.shrink();

    // 1. Boyut Ayarları
    final double firstAvatarSize = 42.r;
    final double otherAvatarSize = 33.r;
    final double overlap = 14.r;

    final items = avatarUrls.take(3).toList();
    final int count = items.length;

    // 2. Toplam Genişlik Hesabı
    double totalWidth = firstAvatarSize;
    if (count > 1) {
      totalWidth += (count - 1) * (otherAvatarSize - overlap);
    }

    return SizedBox(
      height: firstAvatarSize,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomLeft,
        children: List.generate(
          count,
          (index) {
            final isFirst = index == 0;
            final currentSize = isFirst ? firstAvatarSize : otherAvatarSize;

            // Sol pozisyonu hesapla
            double leftPos = 0;
            if (index > 0) {
              leftPos =
                  (firstAvatarSize - overlap) +
                  ((index - 1) * (otherAvatarSize - overlap));
            }

            return Positioned(
              left: leftPos,
              bottom: 0,
              child: SizedBox(
                width: currentSize,
                height: currentSize,
                child: CircleAvatar(
                  radius: currentSize / 2,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: NetworkImage(items[index]),
                  onBackgroundImageError: (_, __) {},
                ),
              ),
            );
          },
        ).reversed.toList(),
      ),
    );
  }
}
