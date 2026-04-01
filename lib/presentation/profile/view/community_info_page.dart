import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/profile/view/components/empty_profile_screen.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/profile/view/components/empty_profile_screen.dart';

// CommunityData modelinin importu eksikse eklemeyi unutma
// import 'package:outnest/domain/entities/community/community_data.dart';

class CommunityInfoPage extends StatelessWidget {
  CommunityInfoPage({
    required this.communityData,
    required this.nameSurname,
    super.key,
  });

  final SessionService _sessionService = getIt<SessionService>();

  final CommunityData?
  communityData; // Null gelebilir dediğin için böyle bıraktım
  final String nameSurname; // Required olduğu için null olmamalı

  @override
  Widget build(BuildContext context) {
    // Type promotion için yerel bir değişkene atıyoruz
    final data = communityData;

    return ValueListenableBuilder(
      valueListenable: _sessionService.stateListenable,
      builder: (context, state, child) {
        // Null kontrolü artık 'data' üzerinden yapılıyor
        if (data == null) {
          return const Scaffold(
            body: Center(
              child: EmptyProfileScreen(
                text: 'Topluluk Bilgileri Mevcut Değil',
                icon: Icon(Icons.people),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundColor,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.iconColor,
                size: 26.sp,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nameSurname, // Artık boş gelme ihtimali yok
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onBackgroundColor,
                  ),
                ),
                SizedBox(width: 6.w),
                Icon(
                  Icons.groups_outlined,
                  color: AppColors.onBackgroundColor,
                  size: 22.sp,
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TEPE FOTOĞRAFI
                Container(
                  width: double.infinity,
                  height: 361.w,
                  decoration: BoxDecoration(
                    color: AppColors.dividerColor,
                    borderRadius: BorderRadius.circular(16.r),
                    image: data.communityPhotoUrl.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              data.communityPhotoUrl,
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: data.communityPhotoUrl.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.groups,
                            size: 80.sp,
                            color: AppColors.textGrey,
                          ),
                        )
                      : null,
                ),

                SizedBox(height: 24.h),

                // 2. BİYOGRAFİ BÖLÜMÜ
                Text(
                  'Topluluk Hakkında',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textGrey,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  data.communityBio.isNotEmpty
                      ? data.communityBio
                      : 'Biyografi bulunmuyor.',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onBackgroundColor,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: 16.h),

                // 3. EKİP ÜYELERİ BÖLÜMÜ
                if (data.communityTeamMembers.isNotEmpty) ...[
                  Text(
                    'Ekip Üyeleri',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textGrey,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: data.communityTeamMembers
                        .map((user) => _buildTeamMember(user))
                        .toList(),
                  ),
                  SizedBox(height: 40.h),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamMember(CompactUserEntity user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 25.r,
          backgroundColor: AppColors.dividerColor,
          // Profil resmi boş gelirse hata vermemesi için kontrol
          backgroundImage: user.profileImageUrl.isNotEmpty
              ? CachedNetworkImageProvider(user.profileImageUrl)
              : null,
          child: user.profileImageUrl.isEmpty
              ? Icon(Icons.person, size: 20.sp)
              : null,
        ),
        SizedBox(height: 4.h),
        SizedBox(
          width: 50.w,
          child: Text(
            user.username,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 8.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.onBackgroundColor,
            ),
          ),
        ),
      ],
    );
  }
}
