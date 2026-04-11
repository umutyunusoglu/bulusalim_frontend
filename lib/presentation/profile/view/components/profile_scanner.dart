import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

class ProfileScannerScreen extends HookConsumerWidget {
  const ProfileScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerController = useMemoized(() => MobileScannerController());
    final isProcessing = useState(false);

    // Widget ağaçtan silindiğinde kamerayı kapat
    useEffect(() {
      return scannerController.dispose;
    }, [scannerController]);

    // Hatalı QR durumunda çıkacak olan özel SnackBar
    void showErrorSnackbar() {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              'QR bir profile ait değil.',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                color: AppColors.successGreen,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          backgroundColor: AppColors.textGrey.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          margin: EdgeInsets.only(
            bottom: 60.h,
            left: 80.w,
            right: 80.w,
          ),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          duration: const Duration(seconds: 2),
          elevation: 0,
        ),
      );
    }

    Future<void> onDetect(BarcodeCapture capture) async {
      if (isProcessing.value) return;

      final barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        final rawValue = barcode.rawValue;
        if (rawValue == null || rawValue.isEmpty) continue;

        isProcessing.value = true;

        // konsolda QR kodun içinde tam olarak ne yazdığını görmek için:
        debugPrint('🔍 TARANAN QR VERİSİ: $rawValue');

        // Daha esnek bir kontrol: Domain ne olursa olsun içinde /profile/ geçiyorsa kabul et
        if (rawValue.contains('/profile/')) {
          await scannerController.stop(); // Kamerayı durdur

          // ID'yi güvenli bir şekilde ayrıştır
          String profileUserId = '';
          final uri = Uri.tryParse(rawValue);

          if (uri != null && uri.pathSegments.isNotEmpty) {
            profileUserId = uri.pathSegments.last;
          } else {
            // Uri patlarsa manuel olarak böl
            profileUserId = rawValue.split('/').last;
          }

          // Eğer linkin sonunda parametre (?id=...) vs. varsa temizle
          profileUserId = profileUserId.split('?').first;

          debugPrint('BULUNAN KULLANICI ID: $profileUserId');

          if (profileUserId.isNotEmpty && context.mounted) {
            context.replace('/share/profile/$profileUserId');
            return;
          }
        }

        // Eğer link içinde '/profile/' yoksa hatalı QR kabul et
        debugPrint('HATALI QR: Profil linki bulunamadı.');
        if (context.mounted) {
          showErrorSnackbar();
          await Future.delayed(const Duration(seconds: 2));
          if (context.mounted) {
            isProcessing.value = false;
          }
        }

        break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Symbols.reply,
                      color: AppColors.tertiaryColor,
                      size: 24.sp,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Symbols.close,
                      color: AppColors.tertiaryColor,
                      size: 24.sp,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Text(
                'Arkadaşının telefonundaki QR kodu\nokut ve profilini görüntüle.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tertiaryColor,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(height: 48.h),

            Container(
              width: 361.w,
              height: 361.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                color: Colors.black,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.r),
                child: MobileScanner(
                  controller: scannerController,
                  onDetect: onDetect,
                  placeholderBuilder: (context) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
