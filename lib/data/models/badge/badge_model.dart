import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/data/models/model.dart';
import 'package:outnest/domain/entities/badges/badge_entity.dart';

class BadgeModel implements Model<BadgeEntity> {
  BadgeModel({
    required this.category,
    required this.tier,
    required this.threshold,
    required this.label,
    required this.info,
    required this.iconURL,
    required this.earnedAt,
  });
  factory BadgeModel.fromFirestore(Map<String, dynamic> data) {
    return BadgeModel(
      category: data['category'] as String,
      tier: data['tier'] as int,
      threshold: data['threshold'] as int,
      label: data['label'] as String,
      info: data['info'] as String,
      iconURL: data['iconURL'] as String,
      earnedAt: (data['earnedAt'] as Timestamp).toDate(),
    );
  }

  factory BadgeModel.fromEntity(BadgeEntity entity) {
    return BadgeModel(
      category: entity.category,
      tier: entity.tier,
      threshold: entity.threshold,
      label: entity.label,
      info: entity.info,
      iconURL: entity.iconURL,
      earnedAt: entity.earnedAt,
    );
  }

  @override
  BadgeEntity toEntity() {
    return BadgeEntity(
      category: category,
      tier: tier,
      threshold: threshold,
      label: label,
      info: info,
      iconURL: iconURL,
      earnedAt: earnedAt,
    );
  }

  /// This method is not implemented because badges are read-only
  /// Badges not meant to be written to Firestore from the client side.
  /// They are likely managed by the backend or an admin interface,
  /// Client only needs to read them.
  @override
  Map<String, dynamic> toFirestore() {
    throw UnimplementedError();
  }

  final String category;
  final int tier;
  final int threshold;
  final String label;
  final String info;
  final String iconURL;
  final DateTime earnedAt;
}
