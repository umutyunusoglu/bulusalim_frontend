import 'dart:io';
import 'package:image/image.dart' as img;

Future<File?> cropImage(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  final original = img.decodeImage(bytes);
  if (original == null) return null;

  final cropWidth = original.width < (original.height * 3 ~/ 4)
      ? original.width
      : original.height * 3 ~/ 4;
  final cropHeight = cropWidth * 4 ~/ 3;

  final offsetX = (original.width - cropWidth) ~/ 2;
  final offsetY = (original.height - cropHeight) ~/ 2;

  final cropped = img.copyCrop(
    original,
    x: offsetX,
    y: offsetY,
    width: cropWidth,
    height: cropHeight,
  );

  final croppedBytes = img.encodeJpg(cropped, quality: 80);
  await file.writeAsBytes(croppedBytes);
  return file;
}
