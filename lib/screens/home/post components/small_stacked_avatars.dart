import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

//  3lü Avatarlar
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

    return SizedBox(
      height: size,
      width: (items.length * (size - overlap)) + overlap,
      child: Stack(
        children: List.generate(items.length, (index) {
          return Positioned(
            left: index * (size - overlap),
            child: CircleAvatar(
              radius: size / 2,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: (size / 2) - 2.r,
                backgroundImage: NetworkImage(items[index]),
                backgroundColor: Colors.grey.shade300,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
