// lib/domain/services/tutorial_persistence_service.dart

import 'package:outnest/domain/services/persistance_service.dart';

/// Stores which user IDs have already seen the tutorial.
/// Key format: "tutorial_seen_<userId>"
class TutorialPersistenceService {
  TutorialPersistenceService({required PersistanceService persistanceService})
    : _persistence = persistanceService;

  final PersistanceService _persistence;

  static String _key(String userId) => 'tutorial_seen_$userId';

  Future<bool> hasSeen(String userId) async {
    return (await _persistence.getBool(_key(userId))) == true;
  }

  Future<void> markAsSeen(String userId) async {
    await _persistence.saveBool(_key(userId), true);
  }
}
