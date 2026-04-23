import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/badges/badge_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/presentation/shared/network_svg.dart';

class BadgeDetailsDialog extends HookConsumerWidget {
  const BadgeDetailsDialog({
    required this.badge,
    required this.currentTier,
    required this.isEarned,
    required this.safeThreshold,
    super.key,
  });

  final BadgeEntity badge;
  final int currentTier;
  final bool isEarned;
  final int safeThreshold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(currentUserEntityProvider);

    final pinnedBadges = userAsyncValue.value?.pinnedBadges ?? <String>[];
    final isPinned = pinnedBadges.contains(badge.label);

    final date = badge.earnedAt;
    final isDateValid = date.year > 1970;
    final dateStr =
        "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    final ratio = (currentTier / safeThreshold).clamp(0.0, 1.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: AppColors.backgroundColor,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SizedBox(
        width: 361.w,
        height: 361.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. İKON
                    SizedBox(
                      width: 140.w,
                      height: 140.w,
                      child: NetworkSvg(
                        url: badge.iconURL,
                        width: 140.w,
                        height: 140.w,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // 2. BAŞLIK
                    Text(
                      badge.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Sf Pro Display',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackgroundColor,
                      ),
                    ),
                    SizedBox(height: 6.h),

                    // 3. DURUM BİLGİSİ / İLERLEME BARI
                    if (isEarned)
                      Text(
                        isDateValid
                            ? 'Kazanılma tarihi: $dateStr'
                            : 'Rozet Kazanıldı!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Sf Pro Display',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textGrey,
                        ),
                      )
                    else
                      Container(
                        height: 16.h,
                        width: 160.w,
                        decoration: BoxDecoration(
                          color: AppColors.dividerColor,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Stack(
                          children: [
                            if (currentTier > 0)
                              FractionallySizedBox(
                                widthFactor: ratio,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                              ),
                            Center(
                              child: Text(
                                '$currentTier/$safeThreshold',
                                style: TextStyle(
                                  fontFamily: 'Sf Pro Display',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: ratio >= 0.5
                                      ? Colors.white
                                      : AppColors.onBackgroundColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 10.h),

                    // 4. AÇIKLAMA METNİ
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontFamily: 'Sf Pro Display',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.onBackgroundColor.withOpacity(0.75),
                          height: 1.2,
                          letterSpacing: 0.2,
                        ),
                        children: [
                          TextSpan(text: '${badge.label} rozeti, '),
                          TextSpan(
                            text: badge.category.isNotEmpty
                                ? badge.category
                                : 'özel',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                ' etiketli ${badge.threshold} buluşmaya katıldığında veya oluşturduğunda kazanılır. Yeni insanlarla tanış, ilk adımı at ve bu rozeti profilinde göster.',
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (isEarned) SizedBox(height: 12.h),

                    // 5. PROFILE EKLE / KALDIR BUTONU
                    if (isEarned)
                      GestureDetector(
                        onTap: () async {
                          final currentUser = userAsyncValue.value;
                          if (currentUser == null) return;

                          var updatedPinnedBadges = List<String>.from(
                            currentUser.pinnedBadges,
                          );

                          if (isPinned) {
                            updatedPinnedBadges.remove(badge.label);
                          } else {
                            if (updatedPinnedBadges.length >= 3) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'En fazla 3 rozet sabitleyebilirsiniz.',
                                  ),
                                ),
                              );
                              return;
                            }
                            updatedPinnedBadges.add(badge.label);
                          }

                          try {
                            await getIt<UserRepository>().updateUser(
                              currentUser.userID,
                              {'pinnedBadges': updatedPinnedBadges},
                            );

                            ref.invalidate(currentUserEntityProvider);
                          } catch (e) {
                            debugPrint('Hata: $e');
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPinned
                                    ? Symbols.person_cancel
                                    : Symbols.person_check,
                                color: AppColors.primaryColor,
                                size: 24.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                isPinned ? 'Profilden Kaldır' : 'Profile Ekle',
                                style: TextStyle(
                                  fontFamily: 'Sf Pro Display',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // KAPAT BUTONU
            Positioned(
              top: 12.h,
              right: 12.w,
              child: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.onBackgroundColor,
                  size: 24.sp,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
