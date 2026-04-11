import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:logger/web.dart';
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
                  final BadgeModel badgeModel = BadgeModel.fromFirestore(
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
          return [];
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
                  final BadgeModel badgeModel = BadgeModel.fromFirestore(
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
    final result = await _firestore
        .collection('users')
        .doc(userID)
        .collection('badges')
        .get()
        .then((snapshot) {
          final badges = snapshot.docs
              .map((doc) {
                try {
                  final BadgeModel badgeModel = BadgeModel.fromFirestore(
                    doc.data(),
                  );
                  return badgeModel.toEntity();
                } catch (e) {
                  _logger.error(
                    'Error parsing user badge document ${doc.id}: $e',
                  );
                  return null;
                }
              })
              .whereType<BadgeEntity>()
              .toList();

          return badges;
        });

    return result;
  }
}
