import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:outnest/application/service_locators/event_verification_service_provider.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/presentation/event_verification/components/build_app_bar.dart';
import 'package:outnest/presentation/event_verification/components/build_main_button.dart';
import 'package:outnest/presentation/shared/utility/get_current_location.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyQrPage extends HookConsumerWidget {
  const MyQrPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMounted = useIsMounted();
    final qrDataFuture = useMemoized(
      () async {
        final currentLocation = await getCurrentLocation(context);
        if (currentLocation == null || !isMounted()) return null;

        final secret = ref
            .read(eventVerificationServiceProvider)
            .createEventVerificationSecret(
              Geolocation(
                latitude: currentLocation.latitude,
                longitude: currentLocation.longitude,
              ),
            );

        return secret;
      },
    );

    final qrDataSnapshot = useFuture(qrDataFuture);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Text(
              'Arkadaşın anlık konumun kullanılarak oluşturulan QR kodunu okutsun ve buluşmada olduğunu onaylasın!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004B73),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: _buildQrContent(qrDataSnapshot),
              ),
            ),
            const Spacer(),
            buildMainButton('Buluşmaya Dön', () {
              Navigator.of(context).pop();
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildQrContent(AsyncSnapshot<String?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF004B73)),
      );
    }

    if (snapshot.hasError || snapshot.data == null) {
      return const Center(
        child: Text(
          'QR Kod üretilemedi.\nLütfen konumu kontrol edip tekrar deneyin.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return QrImageView(
      data: snapshot.data!,
      padding: EdgeInsets.zero,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF004B73),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF004B73),
      ),
    );
  }
}
