import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfileShareBottomSheet extends HookConsumerWidget {
  const ProfileShareBottomSheet({
    super.key,
    required this.username,
    required this.profileImageUrl,
    required this.profileUrl,
    required this.onSharePressed,
  });
  final String username;
  final String profileImageUrl;
  final String profileUrl;
  final VoidCallback onSharePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 18.h),
            decoration: BoxDecoration(
              color: AppColors.textGrey,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Kullanıcı Bilgisi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl.isEmpty
                    ? Icon(Icons.person, size: 20.sp, color: Colors.grey)
                    : null,
              ),
              SizedBox(width: 8.w),
              Text(
                username,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.tertiaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 22.h),

          // QR Kod Alanı
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xFFC6D0D9), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: profileUrl,
              size: 150.w,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.tertiaryColor,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.tertiaryColor,
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Link Görüntüleme ve Kopyalama Alanı
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.link_2,
                  size: 20.sp,
                  color: AppColors.secondaryColor,
                ),
                SizedBox(width: 40.w),
                Expanded(
                  child: Text(
                    profileUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.tertiaryColor,
                    ),
                  ),
                ),
                SizedBox(width: 40.w),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: profileUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bağlantı kopyalandı!')),
                    );
                  },
                  child: Icon(
                    Symbols.content_copy,
                    size: 20.sp,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Profil Bağlantısını Paylaş Butonu
          SizedBox(
            width: double.infinity,
            height: 40.h,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Önce UI'ı kapat
                onSharePressed(); // Sonra mevcut native share sistemini tetikle
              },
              icon: Icon(Symbols.ios_share, size: 24.sp, color: Colors.white),
              label: Text(
                'Profil Bağlantısını Paylaş',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                elevation: 0,
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // QR Okut Butonu
          TextButton.icon(
            onPressed: () {
              // Yönlendirme eklenecek
            },
            icon: Icon(
              Symbols.qr_code_scanner,
              size: 24.sp,
              color: AppColors.tertiaryColor,
            ),
            label: Text(
              'QR Okut',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.tertiaryColor,
              ),
            ),
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}
