import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/presentation/map/view/components/community_event_info_card.dart';

class CommunityEventDetailViewPage extends StatelessWidget {
  const CommunityEventDetailViewPage({
    required this.event,
    super.key,
  });

  final EventEntity event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // 1. KAYDIRILABİLİR İÇERİK
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 8.h, bottom: 180.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KAPAK FOTOĞRAFI
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _buildCoverImage(),
                  ),

                  // ETKİNLİK BİLGİ KARTI
                  CommunityEventInfoCard(
                    profileImageUrl: event.creator.profileImageUrl,
                    communityName: event.creator.username,
                    eventName: event.name,
                    displayAddress: event.displayAddress,
                    startTime: event.startTime,
                    maxParticipants:
                        event.communityMaxParticipants ?? event.capacity,
                    category: event.hobbies.isNotEmpty
                        ? event.hobbies[0]
                        : 'Genel',
                    link: event.communityLink,
                  ),

                  // DETAY BÖLÜMLERİ
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event.communityDescription != null &&
                            event.communityDescription!.isNotEmpty) ...[
                          _buildSection(
                            'Buluşma Hakkında',
                            event.communityDescription!,
                          ),
                        ],
                        if (event.communityRules != null &&
                            event.communityRules!.isNotEmpty &&
                            event.communityRules!.trim() != '•') ...[
                          _buildSection(
                            'Katılım Kuralları & Gereklilikler',
                            event.communityRules!,
                          ),
                        ],
                        if (event.communityVenueInfo != null &&
                            event.communityVenueInfo!.isNotEmpty) ...[
                          _buildSection('Mekan', event.communityVenueInfo!),
                        ],
                        if (event.communityLink != null &&
                            event.communityLink!.isNotEmpty) ...[
                          _buildSection(
                            'Bağlantı',
                            event.communityLink!,
                            isLink: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. "BULUŞMAYA KATIL" BUTONU
          Positioned(
            bottom: 106.h,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Katıl Butonu
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  elevation: 6,
                  shadowColor: AppColors.primaryColor.withOpacity(0.4),
                ),
                icon: Icon(
                  Symbols.confirmation_number,
                  color: Colors.white,
                  size: 22.sp,
                ),
                label: Text(
                  'Buluşmaya Katıl',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
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

  Widget _buildCoverImage() {
    if (event.communityCoverImageUrl != null &&
        event.communityCoverImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Image.network(
          event.communityCoverImageUrl!,
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
