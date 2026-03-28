import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class RegistrationLoadingScreen extends HookWidget {
  const RegistrationLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final videoController = useRef<VideoPlayerController?>(null);
    final isVideoInitialized = useState(false);

    useEffect(() {
      final controller = VideoPlayerController.asset('assets/welcomepage.mp4');
      videoController.value = controller;

      controller
          .initialize()
          .then((_) async {
            await controller.setVolume(0.0);
            await controller.setLooping(true);
            await controller.play();
            isVideoInitialized.value = true;
          })
          .catchError((error) {
            debugPrint('Video yüklenirken hata oluştu: $error');
          });

      return () => controller.dispose();
    }, []);

    final controller = videoController.value;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. ARKA PLAN VİDEOSU
            Positioned.fill(
              child: isVideoInitialized.value && controller != null
                  ? SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
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
                        fontSize: 40.sp,
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
                    SizedBox(height: 16.h),

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
