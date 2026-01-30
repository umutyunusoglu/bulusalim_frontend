import 'dart:io';

import 'package:outnest/domain/services/draft_post_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DraftPostServiceImpl implements DraftPostService {
  /// Fotoğraf yollarını diske (Shared Preferences) kaydeder.
  /// Key formatı: 'draft_EVENTID'
  ///
  @override
  Future<void> saveDraft(String eventId, List<File> photos) async {
    final prefs = await SharedPreferences.getInstance();
    // File listesini dosya yolu (String) listesine çevirip kaydediyoruz.
    final paths = photos.map((file) => file.path).toList();
    await prefs.setStringList('draft_$eventId', paths);
  }

  /// Belirtilen etkinlik ID'si için kayıtlı fotoğrafları getirir.
  @override
  Future<List<File>> getDraft(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList('draft_$eventId');

    if (paths == null || paths.isEmpty) {
      return [];
    }

    // String path'leri File objesine çeviriyoruz.
    // existsSync() ile dosyanın işletim sistemi tarafından silinip silinmediğini kontrol ediyoruz.
    return paths
        .map((path) => File(path))
        .where((file) => file.existsSync())
        .toList();
  }

  /// Paylaşım tamamlandıktan sonra taslağı siler.
  @override
  Future<void> clearDraft(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_$eventId');
  }
}
