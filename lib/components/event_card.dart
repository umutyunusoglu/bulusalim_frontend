import 'package:bulusalim/components/countdown_timer.dart';
import 'package:bulusalim/components/stacked_avatars.dart';
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

    const staticBackgroundImageUrl =
        'https://picsum.photos/seed/tracking/800/600';
    const String staticLocationName = 'İnegöl, Bolu';
    const double staticDistanceInKm = 225;

    // 2. ARAYÜZ (UI) YAPISI
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: Container(
        height: 180.h,
        margin: EdgeInsets.symmetric(vertical: 8.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            children: [
              // KATMAN 1: Arka Plan Resmi
              _buildBackgroundImage(staticBackgroundImageUrl),

              // KATMAN 2: Siyah Karartma (Gradient)
              _buildGradientOverlay(),

              // KATMAN 3: İkonlar
              Positioned(
                top: 16.h,
                right: 16.w,
                child: _buildIconSection(context),
              ),

              // KATMAN 4: İçerik
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
      ),
    );
  }

  // --- YARDIMCI METOTLAR ---

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
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

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

  Widget _buildTopInfoSection(
    BuildContext context,
    List<String> avatarUrls,
    String locationName,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        StackedAvatars(avatarUrls: avatarUrls),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildTitleSection(context, locationName),
        ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context, double distanceInKm) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildTagColumn(context),
        const Spacer(),
        _buildInfoBar(context, distanceInKm),
      ],
    );
  }

  Widget _buildIconSection(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
        SizedBox(width: 8.w),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBar(BuildContext context, double distanceInKm) {
    final participantRatio = '${event.participants.length}/${event.capacity}';
    final labelStyle = Theme.of(context).textTheme.labelSmall;

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
            child: Text('${distanceInKm.toInt()} km', style: labelStyle),
          ),
          SizedBox(width: 6.w),

          // Katılımcı Oranı
          InfoIconText(
            icon: Icons.people_outline,
            child: Text(participantRatio, style: labelStyle),
          ),
          SizedBox(width: 6.w),

          // Geri Sayım
          InfoIconText(
            icon: Icons.access_time,
            child: CountdownTimer(
              targetTime: event.startTime,
            ),
          ),

          // Kilit İkonu
          const SizedBox(width: 6),
          const InfoIconText(icon: Icons.lock_clock, child: SizedBox.shrink()),
        ],
      ),
    );
  }

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
