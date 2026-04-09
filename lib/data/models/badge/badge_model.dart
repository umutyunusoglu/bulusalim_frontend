import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/data/models/model.dart';
import 'package:outnest/domain/entities/badges/badge_entity.dart';

class BadgeModel implements Model<BadgeEntity> {
  BadgeModel({
    required this.badgeID,
    required this.category,
    required this.tier,
    required this.label,
    required this.iconURL,
  });

  factory BadgeModel.fromEntity(BadgeEntity entity) {
    return BadgeModel(
      badgeID: entity.badgeID,
      category: entity.category,
      tier: entity.tier,
      label: entity.label,
      iconURL: entity.iconURL,
    );
  }

  @override
  BadgeEntity toEntity() {
    return BadgeEntity(
      badgeID: badgeID,
      category: category,
      tier: tier,
      label: label,
      iconURL: iconURL,
    );
  }

  factory BadgeModel.fromFirestore(Map<String, dynamic> data) {
    return BadgeModel(
      badgeID: data['badgeID'] as Identifier,
      category: data['category'] as String,
      tier: data['tier'] as int,
      label: data['label'] as String,
      iconURL: data['iconURL'] as String,
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

  final String badgeID;
  final String category;
  final int tier;
  final String label;
  final String iconURL;
}
