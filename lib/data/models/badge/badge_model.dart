import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/core/utils/types/types.dart';
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
    int parseIntSafely(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String parseStringSafely(dynamic value, [String fallback = '']) {
      return value?.toString() ?? fallback;
    }

    return BadgeModel(
      category: parseStringSafely(data['category'], 'Genel'),
      tier: parseIntSafely(data['tier']),
      threshold: parseIntSafely(data['threshold']),
      label: parseStringSafely(data['label'], 'İsimsiz Rozet'),
      info: parseStringSafely(data['info']),
      iconURL: parseStringSafely(data['iconURL']),
      earnedAt: data['earnedAt'] != null && data['earnedAt'] is Timestamp
          ? (data['earnedAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
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
