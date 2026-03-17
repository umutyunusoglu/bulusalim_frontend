import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/event_verification_service.dart';
import 'package:outnest/presentation/event_verification/components/build_app_bar.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';
import 'package:outnest/presentation/shared/utility/get_current_location.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen(this.event, {super.key});

  final EventEntity event;

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final EventVerificationService _verificationService =
      getIt<EventVerificationService>();

  bool _isVerified = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isVerified || _isLoading) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          // Cihazın gerçek konumunu al
          final position = await getCurrentLocation(context);

          if (position == null) {
            // _getCurrentLocation içinde kullanıcıya zaten hata mesajı gösterdik
            return;
          }

          final currentLocation = Geolocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );

          // Backend / Servis çağrısı
          final isVerificationSuccessful = await _verificationService
              .verifyEvent(
                widget.event,
                currentLocation,
                barcode.rawValue!,
              );

          if (!mounted) return;

          if (isVerificationSuccessful) {
            setState(() {
              _isVerified = true;
            });

            _scannerController.stop();

            Future.delayed(const Duration(seconds: 1), () {
              if (!mounted) return;
              context.go(
                '/camera',
                extra: {
                  'event': widget.event,
                },
              );
            });
          } else {
            showErrorPopup(
              context,
              message:
                  'Doğrulama başarısız. Lütfen doğru QR kodu okuttuğunuzdan emin olun.',
            );
          }
        } catch (e) {
          // Ağ hatası, backend hatası veya beklenmeyen herhangi bir Exception durumunda
          debugPrint('QR Doğrulama Hatası: $e');
          showErrorPopup(
            context,
            message:
                "Kod Doğrulanırken Bir Hata Oluştu, Lütfen QR'ın Doğruluğundan Emin Olun!",
          );
        } finally {
          // Hata olsa da olmasa da, yönlendirme (başarı) gerçekleşmediği sürece loading'i kapatmalıyız.
          // mounted kontrolünü yapıp state'i güvenli güncelliyoruz.
          if (mounted && !_isVerified) {
            setState(() {
              _isLoading = false;
            });
          }
        }

        break; // İlk anlamlı QR'ı işledik, döngüyü kır.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      controller: _scannerController,
                      onDetect: _onDetect,
                      placeholderBuilder: (context) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    if (_isLoading)
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
            if (_isVerified)
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
