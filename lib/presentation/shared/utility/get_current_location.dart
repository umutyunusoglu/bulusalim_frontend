import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';

Future<Position?> getCurrentLocation(BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;

  try {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showErrorPopup(
        context,
        message: 'Lütfen cihazınızın konum servislerini açın.',
      );
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showErrorPopup(
          context,
          message: 'Konum izni reddedildi. Lütfen izinleri açın.',
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      showErrorPopup(
        context,
        message: 'Konum izni reddedildi. Lütfen izinleri açın.',
      );
      return null;
    }

    return await Geolocator.getCurrentPosition(
      timeLimit: const Duration(seconds: 10),
      desiredAccuracy: LocationAccuracy.high,
    );
  } catch (e) {
    showErrorPopup(
      context,
      message: 'Konum alınamadı. Konum izinlerinizi kontrol edin.',
    );
    return null;
  }
}
