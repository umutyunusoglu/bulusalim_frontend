import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/data/models/badge/badge_model.dart';
import 'package:outnest/domain/entities/badges/badge_entity.dart';
import 'package:outnest/domain/repositories/badge_repository.dart';

class BadgeRepositoryImpl implements BadgeRepository {
  BadgeRepositoryImpl({
    required FirebaseFirestore firestore,
    required LoggingService logger,
  }) : _firestore = firestore,
       _logger = logger;

  final FirebaseFirestore _firestore;
  final LoggingService _logger;

  @override
  Future<List<BadgeEntity>> getAllBadges() async {
    final result = await _firestore
        .collection('badges')
        .get()
        .then((snapshot) {
          final badges = snapshot.docs
              .map((doc) {
                try {
                  final badgeModel = BadgeModel.fromFirestore(
                    doc.data(),
                  );
                  return badgeModel.toEntity();
                } catch (e) {
                  _logger.error('Error parsing badge document ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<BadgeEntity>()
              .toList();

          return badges;
        })
        .catchError((error) {
          _logger.error('Error fetching badges from Firestore: $error');
          return <BadgeEntity>[];
        });
    return result;
  }

  @override
  Future<List<BadgeEntity>> getBadgesOfCategory(String category) async {
    final result = await _firestore
        .collection('badges')
        .where('category', isEqualTo: category)
        .get()
        .then((snapshot) {
          final badges = snapshot.docs
              .map((doc) {
                try {
                  final badgeModel = BadgeModel.fromFirestore(
                    doc.data(),
                  );
                  return badgeModel.toEntity();
                } catch (e) {
                  _logger.error('Error parsing badge document ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<BadgeEntity>()
              .toList();

          return badges;
        })
        .catchError((error) {
          _logger.error(
            'Error fetching badges of category $category from Firestore: $error',
          );
          return [];
        });

    return result;
  }

  @override
  Future<List<BadgeEntity>> getBadgesOfUser(String userID) async {
    final userBadgesSnapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('badges')
        .get();

    final futures = userBadgesSnapshot.docs.map((userBadgeDoc) async {
      try {
        final globalBadgeDoc = await _firestore
            .collection('badges')
            .doc(userBadgeDoc.id)
            .get();

        if (!globalBadgeDoc.exists) return null;

        final globalData = globalBadgeDoc.data();
        if (globalData == null) return null;

        final merged = {
          ...globalData,
          ...userBadgeDoc.data(),
        };

        return BadgeModel.fromFirestore(merged).toEntity();
      } catch (e) {
        _logger.error('Error parsing badge ${userBadgeDoc.id}: $e');
        return null;
      }
    });

    final results = await Future.wait(futures);
    return results.whereType<BadgeEntity>().toList();
  }
}
