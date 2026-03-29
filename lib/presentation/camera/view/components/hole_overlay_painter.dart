import 'package:flutter/material.dart';

class HoleOverlayPainter extends CustomPainter {
  final double holeSize;
  final double topOffset;
  final double sideOffset;
  final double borderRadius;
  final Color overlayColor;

  HoleOverlayPainter({
    required this.holeSize,
    required this.topOffset,
    required this.sideOffset,
    required this.borderRadius,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(sideOffset, topOffset, holeSize, holeSize),
          Radius.circular(borderRadius),
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, backgroundPath, holePath),
      Paint()..color = overlayColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
