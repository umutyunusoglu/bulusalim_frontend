import 'package:bulusalim/components/skip_button.dart'; // Eğer ayrı dosyadaysa kalsın
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/screens/camera/camera_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CameraSplashScreen extends StatelessWidget {
  const CameraSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka plan rengi tema ile uyumlu olsun
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. KATMAN: İçerik
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Başlıklar
                Text(
                  'Arkadaşının ',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    // Rengi temadan alıyoruz (Genelde onBackgroundColor)
                  ),
                ),
                Text(
                  'telefonuna yaklaş!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 20.h),

                // Açıklama Metni
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: Text(
                    'Fotoğraf yüklemek için telefonunu arkadaşının telefonuna yaklaştırarak fotoğraf paylaşım moduna geçiş yapabilirsin. Unutma, çekeceğin fotoğraflar ay sonunda Dump’ında karşına çıkabilir.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12.sp,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ),

                SizedBox(height: 25.h),

                // Görsel
                Image.asset(
                  'assets/group103.png',
                  height: 540.h,
                  fit: BoxFit.contain,
                ),
              ],
            ),

            // 2. KATMAN: Skip Butonu
            Positioned(
              top: 20.h,
              right: 20.w,
              child: SkipButton(
                text: 'Skip',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
