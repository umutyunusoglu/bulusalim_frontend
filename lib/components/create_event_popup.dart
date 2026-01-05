import 'package:bulusalim/core/constants/theme/color_themes.dart'; // AppColors Importu
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateEventPopup extends StatelessWidget {
  const CreateEventPopup({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 361.w,
      height: 447.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 31.h),
      decoration: BoxDecoration(
        color: AppColors.popupSurface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            // Gölge rengi genelde siyahtır, opacity ile yumuşatılır
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
