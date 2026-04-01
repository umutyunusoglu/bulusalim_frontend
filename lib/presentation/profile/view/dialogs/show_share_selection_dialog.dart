import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/analytics/event_configs/send_event_invitation_analytics_config.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/usecases/send_event_invitation_usecase.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';

Future<void> showShareSelectionDialog(
  BuildContext context, {
  required List<EventEntity> shareEvents,
  required String profileUserID,
  required String username,
  required String profileImageUrl,
}) async {
  var selectedIdx = 0;
  final eventRepository = getIt<EventRepository>();

  final validEvents = <EventEntity>[];
  for (final e in shareEvents) {
    final hasSent = await eventRepository.hasSentInvitation(e, profileUserID);
    if (!hasSent) validEvents.add(e);
  }

  if (!context.mounted) return;

  if (validEvents.isEmpty) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy, size: 48.r, color: Colors.grey),
              SizedBox(height: 16.h),
              Text(
                'Paylaşılacak Buluşma Bulunamadı',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
              SizedBox(height: 8.h),
              if (shareEvents.isEmpty)
                Text(
                  'Henüz aktif bir buluşman bulunmuyor. Önce bir buluşma oluşturmalısın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              if (shareEvents.isNotEmpty)
                Text(
                  'Tüm aktif buluşmalarına zaten davet gönderdin. Yeni davetler gönderebilmek için yeni buluşmalar kurabilir veya mevcut buluşmalarına yeni katılımcılar ekleyebilirsin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: const Text(
                    'tamam',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
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
                    '@$username kullanıcısı ile paylaşacağın buluşmayı seç',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    height: 100.h,
                    child: PageView.builder(
                      itemCount: validEvents.length,
                      onPageChanged: (index) =>
                          setDialogState(() => selectedIdx = index),
                      itemBuilder: (ctx, index) {
                        final event = validEvents[index];
                        final imageUrl = event.creator.profileImageUrl;
                        final isNetwork = imageUrl.startsWith('http');
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 24.r,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: isNetwork
                                  ? CachedNetworkImageProvider(
                                      fixEmulatorUrl(imageUrl),
                                    )
                                  : AssetImage(
                                          FileService.defaultProfileImageUrl(),
                                        )
                                        as ImageProvider,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              event.name ?? 'Buluşma ${index + 1}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(validEvents.length, (index) {
                      return Container(
                        width: 5.w,
                        height: 5.w,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selectedIdx == index
                              ? AppColors.primaryColor
                              : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => ctx.pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF2F2F7),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                          ),
                          child: Text(
                            'vazgeç',
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final event = validEvents[selectedIdx];
                            final navigator = Navigator.of(ctx);
                            navigator.pop();
                            try {
                              await getIt<SendEventInvitation>().call(
                                toID: profileUserID,
                                toUsername: username,
                                toprofileImageUrl: profileImageUrl,
                                eventID: event.eventID,
                                eventName: event.name ?? '',
                              );
                              if (context.mounted) {
                                showInfoPopup(
                                  context,
                                  message: 'Davet başarıyla gönderildi!',
                                );
                              }
                              getIt<AnalyticsService>().logSendEventInvitation(
                                SendEventInvitationAnalyticsConfig(
                                  eventID: event.eventID,
                                  toUserID: profileUserID,
                                ),
                              );
                            } on Exception {
                              if (context.mounted) {
                                showErrorPopup(
                                  context,
                                  message:
                                      'Davet gönderilemedi, lütfen tekrar deneyin.',
                                );
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                          ),
                          child: Text(
                            'paylaş',
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
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
