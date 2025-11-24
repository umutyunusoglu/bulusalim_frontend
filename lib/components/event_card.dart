import 'package:bulusalim/components/countdown_timer.dart';
import 'package:bulusalim/components/stacked_avatars.dart';
import 'package:bulusalim/core/constants/constant.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/screens/home/eventcomponents/info_icon.dart';
import 'package:bulusalim/screens/home/eventcomponents/overlay_tag_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    required this.event,
    required this.participants,
    super.key,
  });

  final EventEntity event;
  final List<EventParticipantEntity> participants;

  @override
  Widget build(BuildContext context) {
    // 1. VERİ HAZIRLIĞI
    // Gelen katılımcı listesinden sadece resim URL'lerini çekiyoruz.
    final dynamicAvatarUrls = participants
        .map((user) => user.profileImageUrl)
        .toList();

    // Eğer hiç katılımcı yoksa tasarım bozulmasın diye statik resimler koyuyoruz.
    const staticAvatarUrls = <String>[
      'https://picsum.photos/seed/avatar1/100/100',
      'https://picsum.photos/seed/avatar2/100/100',
      'https://picsum.photos/seed/avatar3/100/100',
    ];

    final participantAvatarUrls = dynamicAvatarUrls.isNotEmpty
        ? dynamicAvatarUrls
        : staticAvatarUrls;

    // Şimdilik statik tanımlanan diğer veriler (İleride dinamik olacak)
    const staticBackgroundImageUrl =
        'https://picsum.photos/seed/tracking/800/600';
    const String staticLocationName = 'İnegöl, Bolu';
    const double staticDistanceInKm = 225;

    // 2. ARAYÜZ (UI) YAPISI
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        height: 180.h,
        margin: EdgeInsets.symmetric(vertical: 8.h),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            // Stack: Öğeleri üst üste bindirmek için (Resim -> Gölge -> Yazılar)
            children: [
              // KATMAN 1: Arka Plan Resmi
              _buildBackgroundImage(staticBackgroundImageUrl),

              // KATMAN 2: Siyah Karartma (Gradient) - Yazılar okunsun diye
              _buildGradientOverlay(),

              // KATMAN 3: Sağ Üstteki İkonlar (Kaydet & Seçenekler)
              Positioned(
                top: 16.h, // Yukarıdan mesafe
                right: 16.w, // Sağdan mesafe
                child: _buildIconSection(context),
              ),

              // KATMAN 4: İçerik (Avatarlar, Başlık, Etiketler)
              Padding(
                // Pixel overflow (taşma) olmaması için sıkı padding değerleri
                padding: EdgeInsets.only(
                  top: 8.h,
                  left: 16.w,
                  right: 16.w,
                  bottom: 8.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 0.h),
                    // Üst Bilgi Alanı: Avatarlar + Başlık
                    _buildTopInfoSection(
                      context,
                      participantAvatarUrls,
                      staticLocationName,
                    ),

                    // Araya "Spacer" koyarak alt içeriği en alta itiyoruz
                    const Spacer(),

                    // Alt Bilgi Alanı: Etiketler + Km/Süre bilgisi
                    _buildBottomRow(context, staticDistanceInKm),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // YARDIMCI WIDGET METOTLARI

  /// Arka plan resmini oluşturur ve yüklenme durumunu yönetir.
  Widget _buildBackgroundImage(String imageUrl) {
    return Positioned.fill(
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade800,
          ); // Hata olursa gri zemin
        },
      ),
    );
  }

  /// Yazıların okunması için resmin üzerine siyah bir geçiş (gradient) atar.
  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.6), // Üst kısım koyu
              Colors.transparent, // Orta kısım şeffaf
              Colors.black.withOpacity(0.7), // Alt kısım daha koyu
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4, 1.0], // Geçiş noktaları
          ),
        ),
      ),
    );
  }

  /// Sol üstteki avatar grubu ve yanındaki başlık/konum bilgisini içerir.
  Widget _buildTopInfoSection(
    BuildContext context,
    List<String> avatarUrls,
    String locationName,
  ) {
    return Row(
      // [ÖNEMLİ]: Başlık ve konumu, avatarların alt çizgisine hizalar.
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Avatar Grubu Bileşeni
        StackedAvatars(avatarUrls: avatarUrls),

        SizedBox(width: 8.w), // Avatar ile yazı arasındaki boşluk
        // Başlık ve Konum Yazıları
        Expanded(
          child: _buildTitleSection(context, locationName),
        ),
      ],
    );
  }

  /// Alt kısımdaki etiketleri ve sağdaki siyah bilgi çubuğunu içerir.
  Widget _buildBottomRow(
    BuildContext context,
    double distanceInKm,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end, // Alt hizalama
      children: [
        // Sol alt: Etiketler (Yürüyüş, Sohbet vb.)
        _buildTagColumn(context),

        const Spacer(), // Arayı açar
        // Sağ alt: Mesafe, Kişi sayısı, Zaman sayacı
        _buildInfoBar(context, distanceInKm),
      ],
    );
  }

  /// Sağ üst köşedeki ikon grubu (Bookmark ve More).
  Widget _buildIconSection(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Sadece ikonlar kadar yer kaplar
      children: [
        // 1. Kaydet İkonu
        SizedBox(
          width: 24.w,
          height: 24.w,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.bookmark_border, color: Colors.white, size: 24.sp),
            onPressed: () {},
          ),
        ),

        SizedBox(width: 8.w), // İki ikon arası net boşluk
        // 2. Seçenekler İkonu (Üç nokta)
        SizedBox(
          width: 24.w,
          height: 24.w,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.more_vert, color: Colors.white, size: 24.sp),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  /// Başlık (Event Name) ve Konum (Location) metinleri.
  Widget _buildTitleSection(BuildContext context, String locationName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16.sp,
          ),
        ),
        Text(
          locationName,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  /// Sağ alttaki  (Info Bar).
  Widget _buildInfoBar(BuildContext context, double distanceInKm) {
    final participantRatio = '${event.participants.length}/${event.capacity}';

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),

      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mesafe
          InfoIconText(
            icon: Icons.map_outlined,
            child: Text(
              '${distanceInKm.toInt()} km',
              style: kInfoIconTextStyle,
            ),
          ),
          SizedBox(width: 6.w),

          // Katılımcı Oranı
          InfoIconText(
            icon: Icons.people_outline,
            child: Text(participantRatio, style: kInfoIconTextStyle),
          ),
          SizedBox(width: 6.w),

          // Geri Sayım Sayacı
          InfoIconText(
            icon: Icons.access_time,
            child: CountdownTimer(targetTime: event.startTime),
          ),
          SizedBox(width: 6.w),

          // Kilit İkonu
          const InfoIconText(icon: Icons.lock_clock, child: SizedBox.shrink()),
        ],
      ),
    );
  }

  /// Sol alttaki etiket listesi (Tag'ler).
  Widget _buildTagColumn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      // Sadece ilk 2 hobiyi/etiketi alıp ekrana basıyoruz
      children: event.hobbies
          .take(2)
          .map(
            (tag) => OverlayTagChip(
              label: tag,
              // Etiket içeriğine göre ikon seçimi (Basit bir logic)
              icon: tag.toLowerCase().contains('sohbet')
                  ? Icons.chat_bubble_outline
                  : Icons.directions_walk,
            ),
          )
          .toList(),
    );
  }
}
