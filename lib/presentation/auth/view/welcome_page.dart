import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/presentation/shared/login_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/welcomepage.mp4')
      ..initialize()
          .then((_) async {
            await _videoController.setVolume(0.0);
            await _videoController.setLooping(true);
            await _videoController.play();
            setState(() {});
          })
          .catchError((error) {
            debugPrint('Video yüklenirken hata oluştu: $error');
          });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    final url = Uri.parse(urlString);
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
          // 1. KATMAN: ARKA PLAN VİDEOSU
          Positioned.fill(
            child: _videoController.value.isInitialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController.value.size.width,
                        height: _videoController.value.size.height,
                        child: VideoPlayer(_videoController),
                      ),
                    ),
                  )
                : Container(color: Colors.black),
          ),

          // VİDEO ÜZERİNE HAFİF KARARTMA
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // 2. KATMAN: ARAYÜZ (LOGOLAR VE BUTONLAR)
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  SizedBox(height: 140.h),

                  // LOGO
                  Text(
                    'OUTNEST',
                    style: TextStyle(
                      fontFamily: 'Agrandir',
                      fontSize: 60.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // ALT METİN
                  Text(
                    'Sosyalleşmeye hazırlan!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Grift',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),

                  const Spacer(),

                  // --- GİRİŞ YAP BUTONU ---
                  LoginButton(
                    label: 'Giriş Yap',
                    onPress: () => context.push('/login'),
                    width: double.infinity,
                    height: 48.h,
                    backgroundColor: Colors.white,
                    textColor: AppColors.primaryColor,
                  ),

                  SizedBox(height: 16.h),

                  // --- KAYIT OL BUTONU ---
                  LoginButton(
                    label: 'Kayıt Ol',
                    onPress: () => context.push('/register'),
                    width: double.infinity,
                    height: 48.h,
                    backgroundColor: AppColors.primaryColor,
                    textColor: Colors.white,
                  ),

                  SizedBox(height: 8.h),

                  // YASAL METİNLER
                  RichText(
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
                          url: 'https://outnest.app/yasal/kullanici-sozlesmesi',
                        ),
                        const TextSpan(text: ', '),
                        _buildLinkSpan(
                          text: 'Hizmet Koşulları',
                          url: 'https://outnest.app/yasal/hizmet-kosullari',
                        ),
                        const TextSpan(text: ', '),
                        _buildLinkSpan(
                          text: 'Gizlilik Politikası',
                          url: 'https://outnest.app/yasal/gizlilik-politikasi',
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
