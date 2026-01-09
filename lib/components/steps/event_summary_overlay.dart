import 'package:bulusalim/components/event_card.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/user/compact_user_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EventSummaryOverlay extends StatelessWidget {
  const EventSummaryOverlay({
    required this.previewEvent,
    required this.onCancel,
    required this.onConfirm,
    super.key,
  });

  final EventEntity previewEvent;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    // Özet ekranı için boş katılımcı listesi (veya kurucuyu ekleyebilirsiniz)
    final dummyParticipants = <CompactUserEntity>[];

    return Container(
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
                    blurRadius: 4.0,
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
                  participants: dummyParticipants,
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
                      onTap: onCancel,
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

                  SizedBox(width: 16.w),

                  // OLUŞTUR
                  Expanded(
                    child: GestureDetector(
                      onTap: onConfirm,
                      child: Container(
                        height: 50.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
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
