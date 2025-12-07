import 'package:bulusalim/components/login_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TEMA BAĞLANTISI
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          /// 1. Arka Plandaki Ellipse
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

          /// 2. Üstteki 'B' Logosu
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

          /// 3. Ana İçerik
          SizedBox.expand(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 130.h),

                /// BAŞLIK (İstisna Font Kullanımı)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    'Buluşmaya\nHazır Mısın?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      // İSTİSNA: Buraya özel font korunuyor
                      fontFamily: 'QuicksansAccurateICG',

                      // Renk hala dinamik (Marka Turuncusu)
                      color: theme.colorScheme.primary,

                      fontSize: 48.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
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
                ),

                SizedBox(height: 20.h),

                /// "Giriş Yap" Butonu
                LoginButton(
                  label: 'Giriş Yap',
                  onPress: () {
                    Navigator.pushNamed(context, '/explore');
                  },
                  height: 50.h,
                  borderWidth: 2,
                  borderRadius: 40,
                  width: 340.w,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
