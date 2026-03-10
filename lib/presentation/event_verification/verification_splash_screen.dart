import 'package:flutter/material.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';

class ProximityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor, // Hafif kırık beyaz arka plan
      // Ortak AppBar (Geri ve Kapat butonları ile)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.reply,
            color: AppColors.tertiaryColor,
          ), // Lacivert geri oku
          onPressed: () {
            Navigator.pop(context); // Önceki ekrana dön
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.close,
              color: AppColors.tertiaryColor,
            ), // Lacivert kapat X'i
            onPressed: () {
              // Uygulamayı kapatma veya ana ekrana dönme logiği
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
              "Arkadaşının telefonuna yaklaş!",
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
              "Fotoğraf çekip paylaşabilmek için telefonunu arkadaşının telefonuna yaklaştırarak fotoğraf paylaşım moduna geçiş yapabilirsin.\n\nBir buluşma için yalnızca 3 fotoğraf paylaşabilirsin ve çekeceğin fotoğraflar ay sonu Dump’ında karşına çıkabilir.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.tertiaryColor, // Lacivert metin
                height: 1.4, // Satır arası boşluk
              ),
            ),
            const Spacer(), // Başlık ve Image arasındaki boşluğu doldurur
            // GRADYAN LOGO IMAGE ALANI (Tasarım bu)
            Center(
              child: Image.asset(
                'assets/event_verification_logo.png', // Senin hazırladığın PNG dosyasının adı
                width:
                    MediaQuery.of(context).size.width *
                    0.75, // Ekran genişliğinin %75'i kadar
                fit: BoxFit.contain, // Görseli oranlı bir şekilde sığdır
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
                  // QR okuma sayfasına yönlendirme logiği
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
                  "QR oku",
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
