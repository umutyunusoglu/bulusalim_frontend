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
          Positioned(
            left: 20,
            right: 20,
            top: 300,
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
          Positioned(
            left: 0,
            right: 20,
            top: 100,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/b.png'),
                ),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: 100.h),
              Text(
                'Buluşmaya Hazır Mısın?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFE4553F),
                  fontSize: 64.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'QuicksansAccurateICG',
                ),
              ),
              SizedBox(height: 400.h),
              LoginButton(
                label: 'Hesap Oluştur',
                onPress: () {
                  Navigator.pushNamed(context, 'login');
                },
                height: 50,
                borderWidth: 2,
                borderRadius: 40,
                width: 340,
              ),
              SizedBox(height: 20.h),
              LoginButton(
                label: 'Giriş Yap',
                onPress: () {
                  Navigator.pushNamed(context, 'explore');
                },
                height: 50,
                borderWidth: 2,
                borderRadius: 40,
                width: 340,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/*class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.white, //backgroundColor beyaz yapıldı
      body: Stack(
        // fit: StackFit.expand, // Arka planın her zaman tam ekran olmasını garanti eder
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/logo2.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          SafeArea(
            // Telefonun çentik gibi alanlarından içeriği korur
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  SizedBox(height: 50.h),
                  // BAŞLIK
                  Text(
                    'Buluşmaya Hazır Mısın?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFE4553F),
                      fontSize: 50.sp,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'QuicksansAccurateICG',
                    ),
                  ),
                  const Spacer(),
                  LoginButton(
                    label: 'Hesap Oluştur',
                    onPress: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    height: 50.h,
                    borderWidth: 2,
                    borderRadius: 40,
                    width: double.infinity,
                    backgroundColor: Colors.white,
                    textColor: kLoginTextStyle.color, // Renk güncellendi
                    borderColor: kButtonBackgroundColor,
                  ),

                  SizedBox(height: 20.h),
                  LoginButton(
                    label: 'Giriş Yap',
                    onPress: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    height: 50.h,
                    borderWidth: 2,
                    borderRadius: 40,
                    width: double.infinity,
                    backgroundColor: Colors.white,
                    textColor: kLoginTextStyle.color,
                    borderColor: kButtonBackgroundColor,
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/
