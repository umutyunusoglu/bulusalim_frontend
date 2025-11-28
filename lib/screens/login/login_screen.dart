import 'package:bulusalim/components/login_button.dart';
import 'package:bulusalim/components/skip_button.dart';
import 'package:bulusalim/components/text_input.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/screens/bottomnav_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Tema stillerini alıyoruz
    final titleStyle = Theme.of(context).textTheme.headlineSmall;

    return GestureDetector(
      onTap: () {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // bulusalim logosu
                      Image.asset(
                        'assets/bulusalim.png',
                        height: 40.h,
                      ),
                      SizedBox(
                        width: 70.w,
                      ),
                      SkipButton(
                        text: 'skip',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BottomNavScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 70.h),
                  Center(
                    child: Text(
                      'E-posta ',
                      style: titleStyle,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // E-posta Input (İkon ve Hint Text kaldırıldı)
                  const TextInput(),

                  SizedBox(height: 40.h),
                  Center(
                    child: Text(
                      'Şifre',
                      style: titleStyle,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Şifre Input (İkon ve Hint Text kaldırıldı)
                  const TextInput(
                    obsecureText: true,
                  ),

                  SizedBox(height: 180.h),

                  Text(
                    'E-posta adresinize doğrulama kodu gönderilicektir.',
                    textAlign: TextAlign.center,
                    style: titleStyle?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 30.h),
                  //Send Button
                  LoginButton(
                    label: 'Gönder',
                    onPress: () {
                      Navigator.pushNamed(context, '/sign_in');
                    },
                    height: 50.h,
                    borderWidth: 0,
                    borderRadius: 40,
                    width: double.infinity,
                    backgroundColor: AppColors.slateBlue,
                    textColor: Colors.white,
                    borderColor: Colors.transparent,
                  ),
                  SizedBox(height: 40.h),
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
      ),
    );
  }
}
