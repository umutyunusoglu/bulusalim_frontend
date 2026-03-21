import 'package:cached_network_image/cached_network_image.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/domain/services/file_service.dart';

//TODO: Avatar Info'dan tamamen kurtulmak gerekiyor
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
    this.size = 60,
    super.key,
  });

  final List<AvatarInfo> avatarDataList;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatarDataList.isEmpty) return const SizedBox.shrink();

    // 1. Dinamik Boyut Ayarları
    // ScreenUtil (.w) kullanarak ölçekleme yapıyoruz
    final double avatarSize = size.w;

    // Üst üste binme miktarı (Yarı yarıya binmesi için boyurun yarısı)
    final double overlap = (size * 0.5).w;

    // Her bir avatarın ne kadar sağa kayacağı (Görünen kısım)
    final double shiftAmount = avatarSize - overlap;

    // Sadece ilk 3 kişiyi alıyoruz
    final items = avatarDataList.take(3).toList();
    final int count = items.length;

    // 2. Toplam Genişlik Hesabı
    // Formül: (İlk Avatarın Tam Boyu) + ((Kişi Sayısı - 1) * Kayma Miktarı)
    // Örnek (3 kişi, 60 boyut): 60 + (2 * 30) = 120 genişlik
    double totalWidth = avatarSize;
    if (count > 1) {
      totalWidth += (count - 1) * shiftAmount;
    }

    return SizedBox(
      height: avatarSize,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(count, (index) {
          final currentUser = items[index];

          // Pozisyon hesaplama: index * 30 (0, 30, 60...)
          final double leftPos = index * shiftAmount;

          final String profileImageUrl = currentUser.imageUrl;
          final String defaultAsset = FileService.defaultProfileImageUrl();

          return Positioned(
            left: leftPos,
            top: 0,
            bottom: 0,
            // reversed kullandığımız için z-index (derinlik) sırası doğru oturacaktır.
            // Index 0 (En soldaki) en üstte kalacak.
            child: GestureDetector(
              onTap: () {
                if (currentUser.userId.isNotEmpty) {
                  // URL oluştururken path parametresini düzgün veriyoruz
                  context.push('/home/profile/${currentUser.userId}');
                }
              },
              child: Container(
                width: avatarSize,
                height: avatarSize,
                child: ClipOval(
                  child:
                      (profileImageUrl.isNotEmpty &&
                          profileImageUrl.startsWith('http'))
                      ? CachedNetworkImage(
                          imageUrl: fixEmulatorUrl(profileImageUrl),
                          fit: BoxFit.cover,
                          width: avatarSize,
                          height: avatarSize,
                          placeholder: (context, url) => ColoredBox(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            defaultAsset,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          defaultAsset,
                          fit: BoxFit.cover,
                          width: avatarSize,
                          height: avatarSize,
                        ),
                ),
              ),
            ),
          );
        }).reversed.toList(),
      ),
    );
  }
}
