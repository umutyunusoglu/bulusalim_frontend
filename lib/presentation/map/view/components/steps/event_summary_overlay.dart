import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/presentation/shared/event_card/view/event_card.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/types/enums/screen_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EventSummaryOverlay extends StatelessWidget {
  const EventSummaryOverlay({
    required this.previewEvent,
    required this.onCancel,
    required this.onConfirm,
    this.isLoading = false,
    super.key,
  });

  final EventEntity previewEvent;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // Özet ekranı için boş katılımcı listesi (veya kurucuyu ekleyebilirsiniz)
    final currentUser = getIt<SessionService>().currentUser;
    final creator = CompactUserEntity(
      userID: currentUser!.userID,
      username: currentUser.username,
      profileImageUrl: currentUser.profileImageUrl,
      university: currentUser.university,
      nameSurname: null,
      isPrivate: null,
      bio: null,
      accountType: null,
      communityData: null,
    );

    return ColoredBox(
      color: Colors.black.withOpacity(0.5), // Arka plan karartması
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. BAŞLIK
            Text(
              'Buluşma Kartın Hazır!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'SF Pro Display',
                shadows: [
                  Shadow(
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // 2. KART ÖNİZLEME (EventCard Reused)
            SizedBox(
              width: double.infinity,
              child: AbsorbPointer(
                // Kartın içindeki tıklamaları engelle (Sadece görsel)
                child: EventCard(
                  event: previewEvent,
                  participants: [creator],
                  screen: ScreenEnum.map,
                  showJoinButton: false, // Katıl butonu gizli
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // 3. AKSİYON BUTONLARI
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Row(
                children: [
                  // VAZGEÇ
                  Expanded(
                    child: GestureDetector(
                      onTap: isLoading ? null : onCancel,

                      child: Opacity(
                        opacity: isLoading ? 0.5 : 1.0,
                        child: Container(
                          height: 50.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: Text(
                            'vazgeç',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 16.w),

                  // OLUŞTUR
                  Expanded(
                    child: GestureDetector(
                      onTap: isLoading ? null : onConfirm,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 50.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isLoading
                              ? AppColors.primaryColor.withOpacity(0.6)
                              : AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 22.w,
                                height: 22.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Buluşma Oluştur',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
