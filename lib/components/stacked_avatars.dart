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
    // 1. Boyutları tanımla
    final double firstAvatarSize = 42.r; // İlk (büyük) avatar
    final double otherAvatarSize = 33.r; // Diğer (küçük) avatarlar

    // 2. Üst üste binme miktarını tanımla
    final double overlap = 10.r;

    final items = avatarUrls.take(3).toList(); // En fazla 3 avatar göster

    if (items.isEmpty) {
      return SizedBox.shrink(); // Hiç avatar yoksa boş widget döndür
    }

    // Pozisyonlandırılmış widget'ları tutacak geçici liste
    List<Widget> avatarWidgets = [];
    double currentLeftPosition = 0;

    // 3. Avatarları ve pozisyonlarını hesapla
    for (int i = 0; i < items.length; i++) {
      final isFirst = (i == 0);
      final currentSize = isFirst ? firstAvatarSize : otherAvatarSize;

      avatarWidgets.add(
        Positioned(
          left: currentLeftPosition,
          child: CircleAvatar(
            radius: currentSize / 2,
            backgroundColor: Colors.white, // Beyaz border
            child: CircleAvatar(
              radius: currentSize / 2 - 2.r, // İç avatar
              backgroundImage: NetworkImage(items[i]),
              backgroundColor: Colors.grey.shade300,
              onBackgroundImageError: (exception, stackTrace) {
                debugPrint('Avatar yüklenemedi: $exception');
              },
            ),
          ),
        ),
      );

      // Bir sonraki avatarın 'left' pozisyonunu hazırla
      if (isFirst) {
        // İlk (büyük) avatardan sonraki pozisyon
        currentLeftPosition += (firstAvatarSize - overlap);
      } else {
        // Diğer (küçük) avatarlardan sonraki pozisyon
        currentLeftPosition += (otherAvatarSize - overlap);
      }
    }

    // 4. Toplam genişliği hesapla
    double totalWidth;
    if (items.length == 1) {
      totalWidth = firstAvatarSize;
    } else if (items.length == 2) {
      // (Büyük Boyut - Overlap) + Küçük Boyut
      totalWidth = (firstAvatarSize - overlap) + otherAvatarSize;
    } else {
      // (Büyük Boyut - Overlap) + (Küçük Boyut - Overlap) + Küçük Boyut
      totalWidth =
          (firstAvatarSize - overlap) +
          (otherAvatarSize - overlap) +
          otherAvatarSize;
    }

    return SizedBox(
      height: firstAvatarSize, // Yükseklik en büyüğe göre
      width: totalWidth, // Hesaplanmış toplam genişlik
      child: Stack(
        // Listeyi tersine çevirerek 0. indisteki avatarın en üste gelmesini sağla
        children: avatarWidgets.reversed.toList(),
      ),
    );
  }
}
//fotograflar aynı boyutta olması için
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class StackedAvatars extends StatelessWidget {
//   final List<String> avatarUrls;
//   const StackedAvatars({
//     Key? key,
//     required this.avatarUrls,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final double overlap = 20.r;
//     final double size = 33.r;

//     final items = avatarUrls.take(3).toList();

//     return SizedBox(
//       height: size,
//       width: (items.length * (size - overlap)) + overlap,
//       child: Stack(
//         children: List.generate(items.length, (index) {
//           return Positioned(
//             left: index * (size - overlap),
//             child: CircleAvatar(
//               radius: size / 2,
//               backgroundColor: Colors.white,
//               child: CircleAvatar(
//                 radius: size / 2 - 2.r,
//                 backgroundImage: NetworkImage(items[index]),
//                 backgroundColor: Colors.grey.shade300,
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
// }
