import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/event_verification_service.dart';
import 'package:outnest/presentation/event_verification/components/build_app_bar.dart';

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

  // Güvenli Konum Alma Fonksiyonu
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // 1. Konum servisleri açık mı kontrol et
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('Lütfen cihazınızın konum servislerini açın.');
        return null;
      }

      // 2. Uygulama için konum izni verilmiş mi kontrol et
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Konum izni reddedildi. Doğrulama yapılamıyor.');
          return null;
        }
      }

      // 3. İzin kalıcı olarak reddedilmişse
      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar(
          'Konum izni kalıcı olarak reddedilmiş. Lütfen ayarlardan izin verin.',
        );
        return null;
      }

      // Her şey yolundaysa anlık konumu döndür (Timeout ekleyerek sonsuza kadar beklemesini engelliyoruz)
      return await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      // Konum alınırken cihaz bazlı veya zaman aşımı gibi bir hata olursa yakala
      _showErrorSnackBar(
        'Konum alınırken beklenmeyen bir hata oluştu: Cihazınızın GPS\'ini kontrol edin.',
      );
      return null;
    }
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
          final position = await _getCurrentLocation();

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
            _showErrorSnackBar(
              'Doğrulama başarısız. Lütfen doğru QR kodu okuttuğunuzdan emin olun.',
            );
          }
        } catch (e) {
          // Ağ hatası, backend hatası veya beklenmeyen herhangi bir Exception durumunda
          debugPrint('QR Doğrulama Hatası: $e');
          _showErrorSnackBar(
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

  // Tekrarlanan SnackBar kodlarını temizlemek için yardımcı bir fonksiyon
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior
            .floating, // Biraz daha modern bir görünüm için eklendi
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: buildAppBar(),
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
