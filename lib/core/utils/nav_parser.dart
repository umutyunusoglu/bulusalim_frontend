import 'dart:convert';
import 'package:flutter/material.dart'; // Widget ve IconData için gerekli

class NavParseResult {
  final List<Widget> pages;
  final List<IconData> icons;

  NavParseResult({required this.pages, required this.icons});
}

NavParseResult parseAndSortNavConfig({
  required String jsonString,
  required Map<String, Widget> allPages,
  required Map<String, IconData> allIcons,
}) {
  if (jsonString.isEmpty) {
    throw Exception('Remote Config (navbar_order) verisi boş geldi.');
  }

  // 1. JSON verisini işle ve sırala
  final orderMap = jsonDecode(jsonString) as Map<String, dynamic>;

  final entries = orderMap.entries.toList()
    ..sort((a, b) {
      final int ai = (a.value is num)
          ? (a.value as num).toInt()
          : int.tryParse(a.value.toString()) ?? 99;
      final int bi = (b.value is num)
          ? (b.value as num).toInt()
          : int.tryParse(b.value.toString()) ?? 99;
      return ai.compareTo(bi);
    });

  // 2. Geçici listeleri oluştur
  final List<Widget> tempPages = [];
  final List<IconData> tempIcons = [];

  for (var entry in entries) {
    final key = entry.key;
    if (allPages.containsKey(key) && allIcons.containsKey(key)) {
      tempPages.add(allPages[key]!);
      tempIcons.add(allIcons[key]!);
    }
  }

  // 3. Güvenlik kontrolü
  if (tempIcons.length < 2) {
    throw Exception(
      'Navigasyon menüsü oluşturulamadı. (Gelen eleman sayısı: ${tempIcons.length}).'
      ' Lütfen Firebase Remote Config ("navbar_order") verinizi kontrol edin.',
    );
  }

  // 4. İki listeyi 'NavParseResult' içinde döndür
  return NavParseResult(pages: tempPages, icons: tempIcons);
}
