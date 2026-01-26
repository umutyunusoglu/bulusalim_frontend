import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class StaticInfoPage extends StatelessWidget {
  // Mavi Link Metni

  const StaticInfoPage({
    required this.title,
    required this.content,
    required this.linkText,
    required this.linkUrl,
    super.key,
  });
  final String title; // AppBar Başlığı (Örn: Gizlilik Politikası)
  final String content; // Açıklama Metni
  final String linkText;
  final String linkUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(context),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Açıklama Metni
            Text(
              content,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textGrey, // Gri Renk
                height: 1.5, // Satır aralığı
              ),
            ),

            SizedBox(height: 20.h),

            // Mavi Link Metni
            GestureDetector(
              onTap: () {
                final uri = Uri.parse(linkUrl);
                launchUrl(uri);
              },
              child: Text(
                linkText,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.tertiaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.iconColor,
          size: 20.sp,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.onBackgroundColor,
        ),
      ),
      centerTitle: true,
    );
  }
}
