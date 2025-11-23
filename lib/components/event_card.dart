import 'package:bulusalim/components/countdown_timer.dart';
import 'package:bulusalim/components/stacked_avatars.dart';
import 'package:bulusalim/core/constants/constant.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
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
  final List<UserEntity> participants;

  @override
  Widget build(BuildContext context) {
    /// 1. DİNAMİK VERİLER
    final dynamicAvatarUrls = participants
        .map((user) => user.profileImageUrl)
        .toList();

    const staticAvatarUrls = <String>[
      'https://picsum.photos/seed/avatar1/100/100',
      'https://picsum.photos/seed/avatar2/100/100',
      'https://picsum.photos/seed/avatar3/100/100',
    ];
    final participantAvatarUrls = dynamicAvatarUrls.isNotEmpty
        ? dynamicAvatarUrls
        : staticAvatarUrls;

    /// 2. STATİK VERİLER
    const staticBackgroundImageUrl =
        'https://picsum.photos/seed/tracking/800/600';
    const String staticLocationName = 'İnegöl, Bolu';
    const double staticDistanceInKm = 225;

    return Container(
      height: 180.h,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            _buildBackgroundImage(staticBackgroundImageUrl),
            _buildGradientOverlay(),
            Positioned(
              top: 8.h,
              right: 16.w,
              child: _buildIconSection(context),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: 8.h,
                left: 16.w,
                right: 16.w,
                bottom: 16.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),
                  _buildTopInfoSection(
                    context,
                    participantAvatarUrls,
                    staticLocationName,
                  ),
                  const Spacer(),
                  _buildBottomRow(context, staticDistanceInKm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Arka Plan Resmi
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
          return Container(color: Colors.grey.shade800);
        },
      ),
    );
  }

  // 2. Gradient Katmanı
  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
      ),
    );
  }

  // 3. Üst Bilgi (Avatarlar + Başlık/Konum)
  Widget _buildTopInfoSection(
    BuildContext context,
    List<String> avatarUrls,
    String locationName,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StackedAvatars(avatarUrls: avatarUrls),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildTitleSection(context, locationName),
        ),
      ],
    );
  }

  // 4. Alt Sıra (Etiketler + Bilgi Çubuğu)
  Widget _buildBottomRow(
    BuildContext context,
    double distanceInKm,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildTagColumn(context),
        const Spacer(),
        _buildInfoBar(context, distanceInKm),
      ],
    );
  }

  // 5. Sağ Üst İkonlar
  Widget _buildIconSection(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            Icons.bookmark_border,
            color: Colors.white,
            size: 24.sp,
          ),
          onPressed: () {
            /* Kaydet fonksiyonu */
          },
        ),
        IconButton(
          padding: EdgeInsets.only(left: 8.w),
          constraints: const BoxConstraints(),
          icon: Icon(Icons.more_vert, color: Colors.white, size: 24.sp),
          onPressed: () {
            /* Diğer seçenekler */
          },
        ),
      ],
    );
  }

  // 6. Başlık ve Konum Kolonu
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

  // 7. Bilgi Çubuğu
  Widget _buildInfoBar(
    BuildContext context,
    double distanceInKm,
  ) {
    final participantRatio = '${event.participants.length}/${event.capacity}';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoIconText(
            icon: Icons.map_outlined,
            child: Text(
              '${distanceInKm.toInt()} km',
              style: kInfoIconTextStyle,
            ),
          ),
          SizedBox(width: 6.w),
          InfoIconText(
            icon: Icons.people_outline,
            child: Text(participantRatio, style: kInfoIconTextStyle),
          ),
          SizedBox(width: 6.w),
          InfoIconText(
            icon: Icons.access_time,
            child: CountdownTimer(targetTime: event.startTime),
          ),
          SizedBox(width: 6.w),
          const InfoIconText(
            icon: Icons.lock_clock,
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // 8. Etiketler Kolonu
  Widget _buildTagColumn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: event.hobbies
          .take(2)
          .map(
            (tag) => OverlayTagChip(
              label: tag,
              icon: tag.toLowerCase().contains('sohbet')
                  ? Icons.chat_bubble_outline
                  : Icons.directions_walk,
            ),
          )
          .toList(),
    );
  }
}
