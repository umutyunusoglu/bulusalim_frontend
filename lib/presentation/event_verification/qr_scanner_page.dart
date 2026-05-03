import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:outnest/application/service_locators/event_verification_service_provider.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/presentation/event_verification/components/build_app_bar.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';
import 'package:outnest/presentation/shared/utility/get_current_location.dart';

class QRScannerScreen extends HookConsumerWidget {
  const QRScannerScreen(this.event, {super.key});

  final EventEntity event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerController = useMemoized(() => MobileScannerController());

    // Dispose scanner controller when widget is removed from tree
    useEffect(() {
      return scannerController.dispose;
    }, [scannerController]);

    final isVerified = useState(false);
    final isLoading = useState(false);

    final isCooldown = useRef(false);

    final verificationService = ref.watch(eventVerificationServiceProvider);

    Future<void> onDetect(BarcodeCapture capture) async {
      if (isVerified.value || isLoading.value || isCooldown.value) return;

      final barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        final rawValue = barcode.rawValue;
        if (rawValue == null) continue;

        isCooldown.value = true;
        isLoading.value = true;

        try {
          final position = await getCurrentLocation(context);
          if (position == null) return;

          final currentLocation = Geolocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );

          final result = await verificationService.verifyEvent(
            event,
            currentLocation,
            rawValue,
          );

          if (!context.mounted) return;

          result.fold(
            (failure) => showErrorPopup(context, message: failure.message),
            (_) {
              isVerified.value = true;
              scannerController.stop();
              Future.delayed(const Duration(seconds: 1), () {
                if (!context.mounted) return;
                context.go('/camera', extra: {'event': event});
              });
            },
          );
        } catch (e) {
          debugPrint('QR Doğrulama Hatası: $e');
          if (context.mounted) {
            showErrorPopup(
              context,
              message: 'Beklenmeyen bir hata oluştu.',
            );
          }
        } finally {
          if (context.mounted && !isVerified.value) {
            isLoading.value = false;
            isCooldown.value = false;
          }
        }

        break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Text(
              'Arkadaşının telefonundaki QR kodu okut ve buluşmada olduğunu onayla!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.tertiaryColor,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.black,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: scannerController,
                      onDetect: onDetect,
                      placeholderBuilder: (context) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    if (isLoading.value)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (isVerified.value)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Buluşmada olduğun onaylandı!",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              const SizedBox(height: 36),
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
  }
}
