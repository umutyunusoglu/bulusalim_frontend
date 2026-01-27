import 'package:outnest/components/skip_button.dart';
import 'package:outnest/screens/camera/camera_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CameraSplashScreen extends StatelessWidget {
  const CameraSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 1. KATMAN: İçerik (Metinler ve Görsel)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Arkadaşının ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'telefonuna yaklaş!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: Text(
                    'Fotoğraf yüklemek için telefonunu arkadaşının telefonuna yaklaştırarak fotoğraf paylaşım moduna geçiş yapabilirsin. Unutma, çekeceğin fotoğraflar ay sonunda Dump’ında karşına çıkabilir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                  height: 540
                      .h, // Ekran boyutuna göre taşmaması için yükseklik ayarı
                  fit: BoxFit.contain,
                ),
              ],
            ),

            // 2. KATMAN: Skip Butonu (Sol Üst)
            Positioned(
              top: 20.h,
              right: 20.w,
              child: SkipButton(
                text: 'Skip',
                onTap: () {
                  // Butona basılınca Kamera Ekranına git
                  Navigator.push(
                    context,
                    MaterialPageRoute<CameraPage>(
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
