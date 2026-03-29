import 'dart:io';

import 'package:image/image.dart' as img;

Future<File?> cropToSquare(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  final original = img.decodeImage(bytes);
  if (original == null) return null;

  final size = original.width < original.height
      ? original.width
      : original.height;

  final offsetX = (original.width - size) ~/ 2;
  final offsetY = (original.height - size) ~/ 2;

  final cropped = img.copyCrop(
    original,
    x: offsetX,
    y: offsetY,
    width: size,
    height: size,
  );

  final croppedBytes = img.encodeJpg(cropped, quality: 80);
  await file.writeAsBytes(croppedBytes);
  return file;
}
