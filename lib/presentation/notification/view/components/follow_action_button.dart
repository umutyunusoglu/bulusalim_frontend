import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'follow_request_tile.dart'; // FollowStatus enum için

class FollowActionButton extends StatelessWidget {
  const FollowActionButton({
    required this.status,
    required this.isLoading,
    required this.onMainTap,
    required this.onAcceptTap,
    required this.onRejectTap,
    super.key,
  });

  final FollowStatus? status;
  final bool isLoading;
  final VoidCallback onMainTap;
  final VoidCallback onAcceptTap;
  final VoidCallback onRejectTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 20.w,
        height: 20.h,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    switch (status) {
      case FollowStatus.following:
        return GestureDetector(
          onTap: onMainTap,
          child: _buildStatusContainer(
            'takip ediliyor',
            const Color(0xFFF2F2F7),
            AppColors.tertiaryColor,
          ),
        );

      case FollowStatus.sent:
        return GestureDetector(
          onTap: onMainTap,
          child: _buildStatusContainer(
            'istek gönderildi',
            const Color(0xFFF2F2F7),
            AppColors.tertiaryColor,
          ),
        );

      case FollowStatus.none:
      case null:
        return GestureDetector(
          onTap: onMainTap,
          child: _buildStatusContainer(
            'takip et',
            AppColors.primaryColor,
            Colors.white,
            isElevated: true,
          ),
        );

      case FollowStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onAcceptTap,
              child: _buildStatusContainer(
                'kabul et',
                AppColors.primaryColor,
                Colors.white,
                isElevated: true,
              ),
            ),
            SizedBox(width: 4.w),
            GestureDetector(
              onTap: onRejectTap,
              child: _buildStatusContainer(
                'sil',
                const Color(0xFFF2F2F7),
                AppColors.tertiaryColor,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildStatusContainer(
    String text,
    Color bgColor,
    Color textColor, {
    bool isElevated = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: isElevated
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
