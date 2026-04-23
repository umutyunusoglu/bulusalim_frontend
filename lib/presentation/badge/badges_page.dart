import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_badges_provider.dart';
import 'package:outnest/application/providers/badges/all_badges_provider.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/presentation/badge/component/badges_grid_item.dart';

class BadgesPage extends HookConsumerWidget {
  const BadgesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = useState<int>(0);
    final allBadgesAsync = ref.watch(allBadgesProvider);
    final userBadgesAsync = ref.watch(currentUserBadgesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Symbols.reply,
            color: AppColors.onBackgroundColor,
            size: 24.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rozetler',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.onBackgroundColor,
          ),
        ),
      ),
      body: allBadgesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            const Center(child: Text('Sistem rozetleri yüklenemedi')),
        data: (allBadges) {
          return userBadgesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                const Center(child: Text('Kullanıcı verisi hatası')),
            data: (userBadges) {
              final userBadgeMap = {for (final b in userBadges) b.label: b};

              final filteredBadges =
                  allBadges.where((systemBadge) {
                    // Veritabanından gelen gerçek ilerleme değeri
                    final currentTier =
                        userBadgeMap[systemBadge.label]?.tier ?? 0;

                    final isEarned = currentTier >= systemBadge.threshold;
                    final isInProgress = currentTier > 0 && !isEarned;

                    if (selectedFilter.value == 0) return true;
                    if (selectedFilter.value == 1) return isInProgress;
                    if (selectedFilter.value == 2) return isEarned;
                    return true;
                  }).toList()..sort((a, b) {
                    final categoryCompare = a.category.compareTo(b.category);
                    if (categoryCompare != 0) return categoryCompare;
                    return a.threshold.compareTo(b.threshold);
                  });

              return Column(
                children: [
                  SizedBox(height: 16.h),
                  _buildFilterSection(selectedFilter),
                  SizedBox(height: 24.h),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 24.h,
                      ),
                      itemCount: filteredBadges.length,
                      itemBuilder: (context, index) {
                        final badge = filteredBadges[index];

                        final realCurrentTier =
                            userBadgeMap[badge.label]?.tier ?? 0;

                        return BadgeGridItem(
                          badge: badge,
                          currentTier: realCurrentTier,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(ValueNotifier<int> selectedFilter) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _filterBtn('Tümü', 0, selectedFilter),
          _filterBtn('İlerlemeler', 1, selectedFilter),
          _filterBtn('Kazandıklarım', 2, selectedFilter),
        ],
      ),
    );
  }

  Widget _filterBtn(String t, int i, ValueNotifier<int> s) {
    final active = s.value == i;
    return GestureDetector(
      onTap: () => s.value = i,
      child: Container(
        width: 110.w,
        height: 32.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.tertiaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          t,
          style: TextStyle(
            fontFamily: 'Sf Pro Display',
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: active ? AppColors.onPrimaryColor : AppColors.tertiaryColor,
          ),
        ),
      ),
    );
  }
}
