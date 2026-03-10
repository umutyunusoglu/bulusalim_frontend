import 'package:flutter/material.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/presentation/event_verification/components/build_app_bar.dart';
import 'package:outnest/presentation/event_verification/components/build_main_button.dart';

class QRScannerScreen extends StatelessWidget {
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
              "Arkadaşının telefonundaki QR kodu okut ve buluşmada olduğunu onayla!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.tertiaryColor,
              ),
            ),
            const SizedBox(height: 40),
            // Kamera Alanı
            Container(
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: BoxDecoration(
                color: Colors.black, // Buraya Kamera Preview gelecek
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const Spacer(),
            // Onay Rozeti
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            ),
            const SizedBox(height: 16),
            buildMainButton("Buluşmaya Git", () {}),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
