import 'package:flutter_svg/flutter_svg.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/domain/services/remote_config_service.dart';
import 'package:url_launcher/url_launcher.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
    this.trailing,
    this.middleWidget,
  });

  final Widget? trailing;
  final Widget? middleWidget;

  @override
  Widget build(BuildContext context) {
    const iconColor = AppColors.secondaryColor;

    return Container(
      color: Colors.transparent,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            // 1. LOGO
            GestureDetector(
              onTap: () async {
                final url = await getIt<RemoteConfigService>().getValue<String>(
                  'outnest_logo_url',
                );
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: SizedBox(
                width: 30.w,
                height: 30.w,
                child: SvgPicture.asset(
                  'assets/outnest/logo.svg',
                ),
              ),
            ),

            // 2. BOŞLUK
            SizedBox(width: 33.w),

            // 3. ORTA WIDGET
            SizedBox(
              width: 236.w,
              height: 45.h,
              child: Center(
                child: middleWidget ?? const SizedBox(),
              ),
            ),
            // 4. BOŞLUK
            SizedBox(width: 38.w),

            // 5. BİLDİRİM İKONU
            trailing ??
                SizedBox(
                  width: 24.sp,
                  height: 24.sp,
                  child: InkWell(
                    onTap: () {
                      // Bildirimler sayfasına yönlendir
                      context.push('/notifications');
                    },
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // Tıklama efekti yuvarlak
                    child: Icon(
                      Icons.notifications_none_outlined,
                      color: iconColor,
                      size: 24.sp,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
