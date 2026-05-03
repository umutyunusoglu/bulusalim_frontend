import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

class CustomLoadingScreen extends StatelessWidget {
  final String message;

  // Opsiyonel olarak mesajı dışarıdan alabilmek için parametre ekledik
  const CustomLoadingScreen({
    this.message = 'Yükleniyor...',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İndirdiğin Lokasyon Animasyonu
            Lottie.asset(
              'assets/animations/location_loading.json',
              width: 180.w, // Pinin güzel görünmesi için boyut
              height: 180.w,
              fit: BoxFit.contain,
            ),

            SizedBox(height: 16.h),

            // Altındaki Yükleniyor Yazısı
            Text(
              message,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
