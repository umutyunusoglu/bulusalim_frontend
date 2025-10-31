import 'package:bulusalim/components/login_button.dart';
import 'package:bulusalim/components/text_input.dart';
import 'package:bulusalim/core/constants/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        //backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30.h),
                // bulusalim logosu yapımı
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Image.asset(
                          'assets/ellipse5.png',
                          width: 50.w,
                          height: 100.h,
                        ),
                        Image.asset(
                          'assets/b2.png',
                          width: 50.w,
                          height: 80.h,
                        ),
                        Row(
                          children: [
                            const SizedBox(
                              width: 30,
                            ),
                            Image.asset(
                              'assets/ulusalim.png',
                              width: 120.w,
                              height: 86.h,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                //logo bitimi
                SizedBox(height: 70.h),
                Center(
                  child: Text(
                    'E-posta ',
                    style: kLoginTextStyle,
                  ),
                ),
                SizedBox(height: 10.h),

                // E-posta ve Şifre Alanları Eklendi
                const TextInput(),
                SizedBox(height: 40.h),
                Center(
                  child: Text(
                    'Şifre',
                    style: kLoginTextStyle,
                  ),
                ),
                SizedBox(height: 10.h),
                const TextInput(),
                SizedBox(height: 100.h),
                Text(
                  'E-posta adresinize doğrulama kodu gönderilicektir.',
                  style: kLoginTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 30.h),
                LoginButton(
                  label: 'Gönder',
                  onPress: () {
                    Navigator.pushNamed(context, '/sign_in');
                  },
                  height: 50.h,
                  borderWidth: 0,
                  borderRadius: 40,
                  width: double.infinity,
                  backgroundColor: kButtonBackgroundColor,
                  textColor: Colors.white,
                  borderColor: Colors.transparent,
                ),
                SizedBox(height: 20.h),
                Image.asset(
                  'assets/group1.png',
                  width: double.infinity,
                  height: 96.h,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
