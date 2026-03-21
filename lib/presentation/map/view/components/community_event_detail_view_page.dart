import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/types/enums/screen_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/presentation/map/view/components/community_event_info_card.dart';
import 'package:outnest/presentation/shared/event_card/view/components/event_join_button.dart';

class CommunityEventDetailViewPage extends StatelessWidget {
  const CommunityEventDetailViewPage({
    required this.event,
    super.key,
  });

  final EventEntity event;

  @override
  Widget build(BuildContext context) {
    final community = event.communityData;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 8.h, bottom: 180.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _buildCoverImage(community?.coverImageUrl),
                  ),
                  CommunityEventInfoCard(
                    profileImageUrl: event.creator.profileImageUrl,
                    communityName: event.creator.username,
                    eventName: event.name,
                    displayAddress: event.displayAddress,
                    startTime: event.startTime,
                    maxParticipants:
                        community?.maxParticipants ?? event.capacity,
                    category: event.hobbies.isNotEmpty
                        ? event.hobbies[0]
                        : 'Genel',
                    link: community?.link,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (community?.description != null &&
                            community!.description!.isNotEmpty)
                          _buildSection(
                            'Buluşma Hakkında',
                            community.description!,
                          ),
                        if (community?.rules != null &&
                            community!.rules!.isNotEmpty &&
                            community.rules!.trim() != '•')
                          _buildSection(
                            'Katılım Kuralları & Gereklilikler',
                            community.rules!,
                          ),
                        if (community?.venueInfo != null &&
                            community!.venueInfo!.isNotEmpty)
                          _buildSection('Mekan', community.venueInfo!),
                        if (community?.link != null &&
                            community!.link!.isNotEmpty)
                          _buildSection(
                            'Bağlantı',
                            community.link!,
                            isLink: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── KATIL BUTONU ───
          Positioned(
            bottom: 106.h,
            left: 0,
            right: 0,
            child: Center(
              child: EventJoinButton(
                event: event,
                screen: ScreenEnum.communityDetail,
                style: EventJoinButtonStyle.expanded,
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Symbols.reply,
          color: AppColors.onBackgroundColor,
          size: 24.sp,
        ),
        onPressed: () => context.pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            event.creator.username,
            style: TextStyle(
              color: AppColors.onBackgroundColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 8.w),
          Icon(
            Symbols.groups,
            size: 24.sp,
            color: AppColors.onBackgroundColor,
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildCoverImage(String? coverImageUrl) {
    if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Image.network(
          coverImageUrl,
          width: double.infinity,
          height: 360.h,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: 360.h,
        decoration: BoxDecoration(
          color: AppColors.inputFillColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(
          Icons.image_outlined,
          size: 48.sp,
          color: AppColors.textGrey,
        ),
      );
    }
  }

  Widget _buildSection(String title, String content, {bool isLink = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: isLink
                  ? AppColors.tertiaryColor
                  : AppColors.onBackgroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
