import 'package:flutter/material.dart';

void _showCustomToast(
  BuildContext context, {
  required String message,
  required Color contentColor,
  required Color backgroundColor,
}) {
  if (!context.mounted) return;
  final overlayState = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: 120, // Alt kısımdan yüksekliği buradan ayarlayabilirsin
      left: 24, // Ekranın kenarlarına çok yapışmaması için güvenli boşluk
      right: 24,
      child: TweenAnimationBuilder<double>(
        // Ekrana çıkarken yumuşak bir kayma ve belirme animasyonu
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(
              0,
              20 * (1 - value),
            ), // Hafifçe aşağıdan yukarı kayar
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              // İç boşluklar: Çok satırlı metinlerde bile ferah durmasını sağlar
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(40), // Tam hap görünümü
                // DİKKAT: Kenarlık (border) tamamen kaldırıldı!
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: contentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height:
                      1.3, // Satırlar arası boşluk (Görseldeki gibi ferah durması için)
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlayState.insert(overlayEntry);

  // 3 saniye ekranda kalıp kaybolur
  Future.delayed(const Duration(seconds: 3), () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}

// 1. Bilgi / Başarılı İşlem Popup'ı (Görseldeki)
void showInfoPopup(BuildContext context, {required String message}) {
  _showCustomToast(
    context,
    message: message,
    contentColor: const Color(0xFF0D5C75), // Koyu lacivert yazı
    backgroundColor: const Color(0xFFF2F2F7), // Açık gri/beyaz arka plan
  );
}

// 2. Hata Popup'ı
void showErrorPopup(BuildContext context, {required String message}) {
  _showCustomToast(
    context,
    message: message,
    contentColor: const Color(0xFFFF6459), // Kırmızı yazı
    backgroundColor: const Color(0xFFFEF2F2), // Uçuk kırmızı arka plan
  );
}
