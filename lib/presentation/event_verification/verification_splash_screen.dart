import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';

class VerificationSplashScreen extends StatelessWidget {
  const VerificationSplashScreen(this.event, {super.key});
  final EventEntity event;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor, // Hafif kırık beyaz arka plan
      // Ortak AppBar (Geri ve Kapat butonları ile)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: null,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.close,
              color: AppColors.tertiaryColor,
            ), // Lacivert kapat X'i
            onPressed: () {
              // Uygulamayı kapatma veya ana ekrana dönme logiği
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            // BAŞLIK
            const Text(
              "Buluşmada Olduğunu Doğrula",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.tertiaryColor, // Koyu Lacivert
              ),
            ),
            const SizedBox(height: 15),
            // AÇIKLAMA METNİ
            const Text(
              'Fotoğraf çekip paylaşabilmek için arkadaşının Qr’ını okutarak buluşmaya gittiğini doğrulamalısın. Doğrulama işlemi anlık konumunu kullanır.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.tertiaryColor, // Lacivert metin
                height: 1.4, // Satır arası boşluk
              ),
            ),
            const Spacer(), // Başlık ve Image arasındaki boşluğu doldurur
            // GRADYAN LOGO IMAGE ALANI (Tasarım bu)
            AvatarGlow(
              animate: true,
              glowColor: AppColors.darkPrimaryColor,
              duration: const Duration(milliseconds: 2000),
              repeat: true,
              // glowRadiusFactor: 1.0 tam genişliktir.
              // Bunu 0.5 ile 1.0 arasında ayarlayarak yayılımın ne kadar dışa gideceğini seçebilirsin.
              glowRadiusFactor: 0.1,
              glowCount: 3, // Daha zengin bir görünüm için iç içe iki glow
              glowShape: BoxShape.circle,
              curve: Curves.easeOutQuart,
              child: Container(
                // Logonun etrafına biraz boşluk (padding) ekleyerek
                // glow'un görselin tam altından değil, biraz daha dışından başlamasını simüle ediyoruz.
                padding: const EdgeInsets.all(4.0),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/event_verification_logo.png',
                  width:
                      MediaQuery.of(context).size.width *
                      0.70, // Biraz küçülttük ki glow'a alan kalsın
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const Spacer(), // Image ve Buton arasındaki boşluğu doldurur
            // QR OKU BUTONU
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                // Hafif bir gölge efekti
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  final eventID = event.eventID;
                  context.push(
                    '/home/event_verification/qr_scanner',
                    extra: event,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tertiaryColor, // Lacivert buton
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation:
                      0, // Gölge Container'dan geldiği için burayı sıfırladık
                ),
                child: const Text(
                  "QR Okut",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40), // Ekranın en altından boşluk
          ],
        ),
      ),
    );
  }
}
