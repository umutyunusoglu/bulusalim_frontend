import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart'; // go_router eklentisi
import 'package:outnest/core/constants/theme/color_themes.dart';

void showNoEventsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // BAŞLIK
            Text(
              'Şu an bir buluşmada değilsin. Hemen katıl!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ),

            SizedBox(height: 16.h),

            // AÇIKLAMA METNİ
            Text(
              'Gönderi paylaşabilmek için başlamış bir buluşmada bulunman\ngerekiyor. Gönderi paylaşmak için buluşma oluştur ya da başka kullanıcıların buluşmalarına katıl.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 10.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),

            SizedBox(height: 25.h),

            // BULUŞMA OLUŞTUR BUTONU
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context); // Önce popup'ı kapatır
                  context.go(
                    '/map',
                    extra: true,
                  ); // Haritaya/Buluşma oluşturmaya yönlendirir
                },
                borderRadius: BorderRadius.circular(30.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // İkonlu Yuvarlak Alan
                      Container(
                        width: 50.w,
                        height: 50.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_location_alt_outlined,
                          color: const Color(0xFF2E7D32),
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Buton Yazısı
                      Text(
                        'Buluşma Oluştur',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
