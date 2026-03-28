import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class RegistrationLoadingScreen extends StatefulWidget {
  const RegistrationLoadingScreen({super.key});

  @override
  State<RegistrationLoadingScreen> createState() =>
      _RegistrationLoadingScreenState();
}

class _RegistrationLoadingScreenState extends State<RegistrationLoadingScreen> {
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. ARKA PLAN VİDEOSU
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

            // 2. KARARTMA EFEKTİ
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),

            // 3. ARAYÜZ (LOGO + YÜKLENİYOR KISMI)
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    SizedBox(height: 140.h),

                    // ÜST KISIM: LOGO
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

                    // ÜST KISIM: ALT METİN
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

                    // ALT KISIM: YÜKLENİYOR BİLGİSİ
                    Text(
                      'Hesabınız oluşturulurken lütfen\nbekleyiniz...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Grift',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 16.h), // Yazı ile ikon arası boşluk

                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),

                    SizedBox(height: 80.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
