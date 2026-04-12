import 'package:equatable/equatable.dart';

class BadgeEntity extends Equatable {
  const BadgeEntity({
    required this.category,
    required this.tier,
    required this.label,
    required this.threshold,
    required this.info,
    required this.iconURL,
    required this.earnedAt,
  });

  BadgeEntity copyWith({
    String? category,
    int? tier,
    int? threshold,
    String? label,
    String? info,
    String? iconURL,
    DateTime? earnedAt,
  }) {
    return BadgeEntity(
      category: category ?? this.category,
      tier: tier ?? this.tier,
      threshold: threshold ?? this.threshold,
      label: label ?? this.label,
      info: info ?? this.info,
      iconURL: iconURL ?? this.iconURL,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }

  final String category;
  final int tier;
  final int threshold;
  final String label;
  final String info;
  final String iconURL;
  final DateTime earnedAt;

  List<Object?> get props => [
    category,
    tier,
  ];
}
