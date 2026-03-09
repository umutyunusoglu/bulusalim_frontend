import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/presentation/profile/view/components/empty_profile_screen.dart';

class ProfileDumpTab extends StatelessWidget {
  const ProfileDumpTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return EmptyProfileScreen(
      text:
          "Dump'ın Hazırlanıyor... Fotoğraf paylaşmaya devam et, ay sonunda sonucu gör.",
      icon: Icon(
        Icons.auto_awesome_motion_outlined,
        size: 48.sp,
        color: AppColors.tertiaryColor.withOpacity(0.7),
      ),
    );
  }
}
