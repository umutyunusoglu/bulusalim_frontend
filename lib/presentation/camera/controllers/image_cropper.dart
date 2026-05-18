import 'dart:io';
import 'package:image/image.dart' as img;

Future<File?> cropImage(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  final original = img.decodeImage(bytes);
  if (original == null) return null;

  // Desired aspect ratio (width / height) => 3:4
  const double targetAspect = 3 / 4;

  final origW = original.width.toDouble();
  final origH = original.height.toDouble();

  int cropW;
  int cropH;

  if ((origW / origH) > targetAspect) {
    // Image is wider than target aspect -> crop width
    cropH = original.height;
    cropW = (origH * targetAspect).round();
  } else {
    // Image is taller (or narrower) than target -> crop height
    cropW = original.width;
    cropH = (origW / targetAspect).round();
  }

  final offsetX = ((original.width - cropW) / 2).round();
  final offsetY = ((original.height - cropH) / 2).round();

  final cropped = img.copyCrop(
    original,
    x: offsetX,
    y: offsetY,
    width: cropW,
    height: cropH,
  );

  final croppedBytes = img.encodeJpg(cropped, quality: 80);
  await file.writeAsBytes(croppedBytes);
  return file;
}
