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
    // TEMA BAĞLANTISI
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary; // Turuncu

    return GestureDetector(
      onTap: () {
        // Klavyeyi kapatmak için
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        // Arka plan rengi temadan gelir (Genelde Beyaz)
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            // Taşma riskine karşı scroll eklendi
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ÜST KISIM (Logo ve Skip) ---
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo (Sola yaslı değilse Spacer ile itebiliriz ama görselde sağda skip var)
                      // Mevcut koda sadık kalarak, logonun konumunu koruyoruz.
                      const Spacer(),

                      Image.asset(
                        'assets/bulusalim.png',
                        height: 32.h,
                      ),

                      const Spacer(),

                      SkipButton(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BottomNavScreen(),
                            ),
                          );
                        },
                        text: 'skip',
                        // Renk otomatik olarak AppTheme.tertiary (#004B75) alır
                      ),
                    ],
                  ),

                  SizedBox(height: 60.h),

                  // --- E-POSTA ALANI ---
                  Center(
                    child: Text(
                      'E-posta',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: 'Urbanist',
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: Colors.black, // Başlıklar net Siyah
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  const TextInput(
                    hintText: 'E-posta adresinizi giriniz',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  SizedBox(height: 30.h),

                  // --- ŞİFRE ALANI ---
                  Center(
                    child: Text(
                      'Şifre',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: 'Urbanist',
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  const TextInput(
                    hintText: 'Şifrenizi giriniz',
                    obscureText: true,
                  ),

                  SizedBox(height: 100.h),

                  // --- BİLGİLENDİRME METNİ ---
                  Center(
                    child: Text(
                      'E-posta adresinize doğrulama kodu gönderilecektir.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Urbanist',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600, // Daha yumuşak gri
                      ),
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // --- GÖNDER BUTONU ---
                  // LoginButton veya CustomButton kullanabilirsin.
                  // Burada LoginButton'a renkleri manuel geçerek özelleştiriyoruz.
                  LoginButton(
                    label: 'Gönder',
                    onPress: () {
                      // Navigator.pushNamed(context, '/sign_in'); // Akışa göre değişir
                    },
                    height: 50.h,
                    borderWidth: 0,
                    borderRadius: 40,
                    width: double.infinity,
                    // DİNAMİK RENKLER:
                    backgroundColor: AppColors.secondaryColor,
                    textColor: Colors.white,
                    borderColor: Colors.transparent,
                  ),

                  SizedBox(height: 40.h),
                  Image.asset(
                    'assets/group1.png',
                    width: double.infinity,
                    height: 96.h,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
