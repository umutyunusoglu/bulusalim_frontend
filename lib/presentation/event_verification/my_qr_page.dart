import 'package:flutter/material.dart';
import 'package:outnest/presentation/event_verification/components/build_app_bar.dart';
import 'package:outnest/presentation/event_verification/components/build_main_button.dart';

class MyQrPage extends StatelessWidget {
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
              'Arkadaşının telefonundan QR kodunu okutsun ve buluşmada olduğunu onaylasın!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004B73),
              ),
            ),
            const SizedBox(height: 40),
            // QR Kod Çerçevesi
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const AspectRatio(
                aspectRatio: 1,
                child: Center(
                  child: Text(
                    'QR',
                    style: TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            buildMainButton('Buluşmaya Dön', () {}),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
