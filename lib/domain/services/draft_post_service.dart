import 'dart:io';

abstract class DraftPostService {
  Future<void> saveDraft(String eventId, List<File> photos);

  Future<List<File>> getDraft(String eventId);
  Future<void> clearDraft(String eventId);
}
