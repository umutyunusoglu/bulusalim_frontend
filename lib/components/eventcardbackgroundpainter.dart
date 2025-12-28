// Dosya Yolu: lib/components/event_card_background_painter.dart

import 'package:flutter/material.dart';

class EventCardBackgroundPainter extends CustomPainter {
  final Color backgroundColor;
  final double bumpRadius;
  final double bumpOffset;

  EventCardBackgroundPainter({
    required this.backgroundColor,
    required this.bumpRadius,
    required this.bumpOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = backgroundColor;

    // KARTIN GÖLGESİ
    // CSS Karşılığı: box-shadow: 0px 4px 4px 0px #00000026;
    final Paint shadowPaint = Paint()
      ..color =
          const Color(0x26000000) // #00000026 (%15 opaklıkta siyah)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4); // Blur: 4px

    // 1. Kartın Dikdörtgen Gövdesi
    final Path cardPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(24),
        ),
      );

    // 2. Çıkıntı (Daire)
    // Merkez Y: bumpRadius (27) - bumpOffset (24) = 3px içeriden başlar
    final double circleCenterY = bumpRadius - bumpOffset;

    final Path knobPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, circleCenterY),
          radius: bumpRadius,
        ),
      );

    // 3. İki şekli birleştir (Union)
    final Path combinedPath = Path.combine(
      PathOperation.union,
      cardPath,
      knobPath,
    );

    // Önce gölgeyi çiz (0, 4 offset ile aşağı kaydırarak)
    canvas.drawPath(combinedPath.shift(const Offset(0, 4)), shadowPaint);

    // Sonra şeklin kendisini çiz
    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
