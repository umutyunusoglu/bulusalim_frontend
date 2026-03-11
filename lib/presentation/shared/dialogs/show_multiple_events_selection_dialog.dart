import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/file_service.dart';

void showMultipleEventsSelectionDialog(
  BuildContext context,
  List<dynamic> activeEvents,
) {
  var selectedIndex = 0;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Şu an hangi buluşmada olduğunu seç',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Carousel
                  SizedBox(
                    height: 100.h,
                    child: PageView.builder(
                      itemCount: activeEvents.length,
                      onPageChanged: (index) {
                        setState(() => selectedIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final event = activeEvents[index] as EventEntity;

                        // Mock veriyi de gerçek veriyi de karşılayacak şekilde
                        final eventName =
                            event.name.toString() ?? 'Buluşma ${index + 1}';

                        final participants = event.participants;
                        // Mock listede veya gerçek entity'de imageUrls erişimi

                        final eventImage =
                            event.creator.profileImageUrl.isNotEmpty
                            ? event.creator.profileImageUrl
                            : FileService.defaultProfileImageUrl();

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 24.r,
                              backgroundImage: eventImage.startsWith('http')
                                  ? CachedNetworkImageProvider(
                                      fixEmulatorUrl(eventImage),
                                    )
                                  : AssetImage(eventImage),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              eventName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Dots Indicator
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(activeEvents.length, (index) {
                      return Container(
                        width: 5.w,
                        height: 5.w,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selectedIndex == index
                              ? AppColors.primaryColor
                              : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),

                  SizedBox(height: 16.h),
                  Text(
                    'Birden fazla aktif buluşmada olduğun için hangi buluşmada olduğunu seçmelisin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                  SizedBox(
                    height: 24.h,
                  ), // Butonlar ile yazı arasını biraz açtım
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Butonları ortala
                    children: [
                      // VAZGEÇ BUTONU
                      SizedBox(
                        width: 77.w,
                        height: 34.h,
                        child: TextButton(
                          onPressed: () => context.pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF2F2F7),
                            padding: EdgeInsets.zero, // Padding sıfırlandı
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                          ),
                          child: Text(
                            'vazgeç',
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600, // Kalınlık artırıldı
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w), // Butonlar arası boşluk
                      // İLERLE BUTONU
                      SizedBox(
                        width: 77.w,
                        height: 34.h,
                        child: TextButton(
                          onPressed: () {
                            context
                              ..pop()
                              ..push(
                                '/camera',
                                extra: {'event': activeEvents[selectedIndex]},
                              );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: EdgeInsets.zero, // Padding sıfırlandı
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                          ),
                          child: Text(
                            'ilerle',
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600, // Kalınlık artırıldı
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
