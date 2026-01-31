import 'package:cached_network_image/cached_network_image.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AvatarInfo {
  AvatarInfo({
    required this.userId,
    required this.imageUrl,
  });
  final String userId;
  final String imageUrl;
}

class StackedAvatars extends StatelessWidget {
  const StackedAvatars({
    required this.avatarDataList,
    this.size = 50,
    super.key,
  });

  final List<AvatarInfo> avatarDataList;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatarDataList.isEmpty) return const SizedBox.shrink();

    // 1. Ayarlar
    final avatarSize = size.w;
    final overlap = (size * 0.5).w;

    // İlk 3 kişiyi alıyoruz
    final items = avatarDataList.take(3).toList();
    final count = items.length;

    // 2. Toplam Genişlik Hesabı
    // İlk avatarın tam boyutu + diğerlerinin görünen kısmı (boyut - overlap)
    var totalWidth = avatarSize;
    if (count > 1) {
      totalWidth += (count - 1) * (avatarSize - overlap);
    }

    return SizedBox(
      height: avatarSize,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children:
            List.generate(
                  count,
                  (index) {
                    final currentUser = items[index];

                    // Sol pozisyon: Her eleman (Boyut - Overlap) kadar sağa kayar
                    final leftPos = index * (avatarSize - overlap);

                    return Positioned(
                      left: leftPos,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () {
                          if (currentUser.userId.isNotEmpty) {
                            context.push('/home/profile/${currentUser.userId}');
                          }
                        },
                        child: Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: fixEmulatorUrl(currentUser.imageUrl),
                              fit: BoxFit.cover,
                              errorWidget: (context, error, stackTrace) {
                                return ColoredBox(
                                  color: Colors.grey.shade300,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: avatarSize / 2,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
                // reversed: Listeyi ters çeviriyoruz ki ilk eleman (index 0)
                // yığının en üstünde (en sağda veya en solda çizim sırasına göre) görünsün.
                // Bu haliyle: Index 0 EN ÜSTTE durur.
                .reversed
                .toList(),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';

// class AvatarInfo {
//   AvatarInfo({
//     required this.userId,
//     required this.imageUrl,
//   });
//   final String userId;
//   final String imageUrl;
// }

// class StackedAvatars extends StatelessWidget {
//   const StackedAvatars({
//     required this.avatarDataList,
//     super.key,
//   });
//   final List<AvatarInfo> avatarDataList;

//   @override
//   Widget build(BuildContext context) {
//     if (avatarDataList.isEmpty) return const SizedBox.shrink();

//     // 1. Boyut Ayarları
//     final firstAvatarSize = 42.r;
//     final otherAvatarSize = 33.r;
//     final overlap = 14.r;

//     // İlk 3 kişiyi alıyoruz
//     final items = avatarDataList.take(3).toList();
//     final count = items.length;

//     // 2. Toplam Genişlik Hesabı
//     var totalWidth = firstAvatarSize;
//     if (count > 1) {
//       totalWidth += (count - 1) * (otherAvatarSize - overlap);
//     }

//     return SizedBox(
//       height: firstAvatarSize,
//       width: totalWidth,
//       child: Stack(
//         clipBehavior: Clip.none,
//         alignment: Alignment.bottomLeft,
//         children: List.generate(
//           count,
//           (index) {
//             final isFirst = index == 0;
//             final currentSize = isFirst ? firstAvatarSize : otherAvatarSize;

//             // O anki kullanıcının verisi (ID + Foto)
//             final currentUser = items[index];

//             // Sol pozisyonu hesapla
//             double leftPos = 0;
//             if (index > 0) {
//               leftPos =
//                   (firstAvatarSize - overlap) +
//                   ((index - 1) * (otherAvatarSize - overlap));
//             }

//             return Positioned(
//               left: leftPos,
//               bottom: 0,
//               // Tıklama ve Navigasyon İşlemi
//               child: GestureDetector(
//                 onTap: () {
//                   if (currentUser.userId.isNotEmpty) {
//                     context.push('/home/profile/${currentUser.userId}');
//                   }
//                 },
//                 child: SizedBox(
//                   width: currentSize,
//                   height: currentSize,
//                   child: ClipOval(
//                     child: CachedNetworkImage(
//                       currentUser.imageUrl,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         return ColoredBox(
//                           color: Colors.grey.shade300,
//                           child: Icon(
//                             Icons.person,
//                             color: Colors.grey,
//                             size: currentSize / 2,
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         ).reversed.toList(),
//       ),
//     );
//   }
// }
