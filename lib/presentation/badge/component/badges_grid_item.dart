import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/badges/badge_entity.dart';
import 'package:outnest/presentation/badge/component/badge_details_dialog.dart';
import 'package:outnest/presentation/shared/network_svg.dart';

class BadgeGridItem extends StatelessWidget {
  const BadgeGridItem({
    required this.badge,
    required this.currentTier,
    super.key,
  });

  final BadgeEntity badge;
  final int currentTier;

  @override
  Widget build(BuildContext context) {
    final safeThreshold = badge.threshold > 0 ? badge.threshold : 1;
    final isEarned = badge.threshold > 0 && currentTier >= badge.threshold;
    final hasProgress = currentTier > 0;

    final ratio = (currentTier / safeThreshold).clamp(0.0, 1.0);

    final Widget svgIcon = SizedBox(
      width: 107.w,
      height: 107.w,
      child: NetworkSvg(
        url: badge.iconURL,
        width: 107.w,
        height: 107.w,
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => BadgeDetailsDialog(
            badge: badge,
            currentTier: currentTier,
            isEarned: currentTier >= badge.threshold,
            safeThreshold: badge.threshold > 0 ? badge.threshold : 1,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isEarned)
            svgIcon
          else
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: Opacity(
                opacity: 0.6,
                child: svgIcon,
              ),
            ),
          SizedBox(height: 12.h),
          Text(
            badge.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.onBackgroundColor,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            height: 12.h,
            width: 96.w,
            decoration: BoxDecoration(
              color: AppColors.dividerColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Stack(
              children: [
                if (hasProgress)
                  FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isEarned
                            ? AppColors.successGreen
                            : AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                Center(
                  child: Text(
                    '$currentTier/${badge.threshold}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: hasProgress
                          ? AppColors.onPrimaryColor
                          : AppColors.onBackgroundColor,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
