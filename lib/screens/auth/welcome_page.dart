import 'package:bulusalim/components/login_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Link açılamadı: $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. KATMAN: ARKA PLAN RESMİ
          Positioned.fill(
            child: Image.asset(
              'assets/image2.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.black),
            ),
          ),

          // // 2. KATMAN: KARARTMA
          // Positioned.fill(
          //   child: Container(
          //     decoration: BoxDecoration(
          //       gradient: LinearGradient(
          //         begin: Alignment.topCenter,
          //         end: Alignment.bottomCenter,
          //         colors: [
          //           Colors.black.withOpacity(0.1),
          //           Colors.black.withOpacity(0.4),
          //           Colors.black.withOpacity(0.9),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),

          // 3. KATMAN: İÇERİK
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // LOGO
                  Image.asset(
                    'assets/outnest.png',
                    height: 60.h,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        'outnest',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 40.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 4),

                  // --- GİRİŞ YAP BUTONU ---
                  // İstenilen boyutlar: 205w, 48h, 40r
                  LoginButton(
                    label: 'Giriş Yap',
                    onPress: () => context.push('/login'),
                    width: 205.w,
                    height: 48.h,
                  ),

                  SizedBox(height: 16.h),

                  // --- KAYIT OL BUTONU ---
                  LoginButton(
                    label: 'Kayıt Ol',
                    onPress: () => context.push('/register'),
                    width: 205.w,
                    height: 48.h,
                  ),

                  // DEBUG BUTONU
                  LoginButton(
                    label: 'Debug',
                    onPress: () => context.push('/debug'),
                    width: 205.w,
                    height: 48.h,
                    borderRadius: 40.r,
                  ),

                  SizedBox(height: 8.h),

                  // YASAL METİNLER
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 11.sp,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'Devam ederek Outnest’in '),
                          _buildLinkSpan(
                            text: 'Kullanıcı Sözleşmesi',
                            url:
                                'https://outnest.app/yasal/kullanici-sozlesmesi',
                          ),
                          const TextSpan(text: ', '),
                          _buildLinkSpan(
                            text: 'Hizmet Koşulları',
                            url: 'https://outnest.app/yasal/hizmet-kosullari',
                          ),
                          const TextSpan(text: ', '),
                          _buildLinkSpan(
                            text: 'Gizlilik Politikası',
                            url:
                                'https://outnest.app/yasal/gizlilik-politikasi',
                          ),
                          const TextSpan(text: ' ve '),
                          _buildLinkSpan(
                            text: 'Aydınlatma Metni',
                            url: 'https://outnest.app/yasal/aydinlatma-metni',
                          ),
                          const TextSpan(text: '’ni kabul etmiş oluyorsunuz.'),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _buildLinkSpan({required String text, required String url}) {
    return TextSpan(
      text: text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.underline,
        color: Colors.white,
      ),
      recognizer: TapGestureRecognizer()..onTap = () => _launchURL(url),
    );
  }
}
