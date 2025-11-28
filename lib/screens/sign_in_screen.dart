import 'package:bulusalim/components/login_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Arka plandaki ellipse
          Positioned(
            left: 20.w,
            right: 20.w,
            top: 300.h,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/ellipse.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),

          /// Üstteki b.png görseli
          Positioned(
            left: 0,
            right: 20.w,
            top: 350.h,
            child: Container(
              height: 250.h,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/b.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          /// Ana içerik
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 100.h),

              /// Başlık
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  'Buluşmaya Hazır Mısın?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFE4553F),
                    fontSize: 50.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'QuicksansAccurateICG',
                  ),
                ),
              ),
              SizedBox(height: 400.h),

              /// "Hesap Oluştur" Butonu
              LoginButton(
                label: 'Hesap Oluştur',
                onPress: () {
                  Navigator.pushNamed(context, '/login');
                },
                height: 50.h,
                borderWidth: 2,
                borderRadius: 40,
                width: 340.w,
                // Renkler belirtilmediği için LoginButton varsayılan (SlateBlue) temasını kullanır.
              ),

              SizedBox(height: 20.h),

              /// "Giriş Yap" Butonu
              LoginButton(
                label: 'Giriş Yap',
                onPress: () {
                  // Rota yapınıza göre burası değişebilir, mevcut kodunuzdaki gibi bıraktım
                  Navigator.pushNamed(context, '/explore');
                },
                height: 50.h,
                borderWidth: 2,
                borderRadius: 40,
                width: 340.w,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
