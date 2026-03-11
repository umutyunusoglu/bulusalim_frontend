import 'dart:io';

import 'package:outnest/domain/services/draft_post_service.dart';
import 'package:outnest/domain/services/persistance_service.dart';

class DraftPostServiceImpl implements DraftPostService {
  // Bağımlılık (Dependency) dışarıdan alınıyor
  DraftPostServiceImpl({
    required PersistanceService persistanceService,
  }) : _persistanceService = persistanceService;

  final PersistanceService _persistanceService;

  /// Fotoğraf yollarını diske (Hive üzerinden) kaydeder.
  /// Key formatı: 'draft_EVENTID'
  @override
  Future<void> saveDraft(String eventId, List<File> photos) async {
    final paths = photos.map((file) => file.path).toList();

    // PersistanceService'in saveJson metodu Map beklediği için,
    // listemizi bir 'paths' anahtarı ile JSON formatına sarıyoruz.
    await _persistanceService.saveJson(
      'draft_$eventId',
      {'paths': paths},
    );
  }

  /// Belirtilen buluşma ID'si için kayıtlı fotoğrafları getirir.
  @override
  Future<List<File>> getDraft(String eventId) async {
    // Veriyi JSON formatında okuyoruz
    final data = await _persistanceService.getJson('draft_$eventId');

    if (data == null || !data.containsKey('paths')) {
      return [];
    }

    // Gelen veriyi güvenli bir şekilde List<String>'e dönüştürüyoruz (Casting)
    final paths = List<String>.from(data['paths'] as List);

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
    await _persistanceService.delete('draft_$eventId');
  }
}
