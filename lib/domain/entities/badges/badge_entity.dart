import 'package:equatable/equatable.dart';
import 'package:outnest/core/utils/types/types.dart';

class BadgeEntity extends Equatable {
  const BadgeEntity({
    required this.badgeID,
    required this.category,
    required this.tier,
    required this.label,
    required this.iconURL,
  });

  BadgeEntity copyWith({
    Identifier? badgeID,
    String? category,
    int? tier,
    String? label,
    String? iconURL,
  }) {
    return BadgeEntity(
      badgeID: badgeID ?? this.badgeID,
      category: category ?? this.category,
      tier: tier ?? this.tier,
      label: label ?? this.label,
      iconURL: iconURL ?? this.iconURL,
    );
  }

  final Identifier badgeID;
  final String category;
  final int tier;
  final String label;
  final String iconURL;

  List<Object?> get props => [
    badgeID,
  ];
}
