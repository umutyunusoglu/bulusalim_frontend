import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/presentation/settings/view/components/add_authority.dart';

class CommunityInfoPage extends StatelessWidget {
  const CommunityInfoPage({
    required this.communityName,
    required this.imageUrl,
    required this.bioText,
    required this.teamMembers,
    super.key,
  });
  final String communityName;
  final String imageUrl;
  final String bioText;
  final List<AuthorityUserModel> teamMembers;

  @override
  Widget build(BuildContext context) {
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
              communityName,
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
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
        ),
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
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // 2. BİOGRAFİ BÖLÜMÜ
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
              bioText,
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

            // Ekip üyeleri grid'i
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: teamMembers
                  .map((user) => _buildTeamMember(user))
                  .toList(),
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  // Ekip üyesi avatar ve isim bileşeni
  Widget _buildTeamMember(AuthorityUserModel user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 25.r,
          backgroundColor: AppColors.dividerColor,
          backgroundImage: NetworkImage(user.imageUrl),
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
