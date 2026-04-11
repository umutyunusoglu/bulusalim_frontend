import 'package:equatable/equatable.dart';
import 'package:outnest/core/utils/types/types.dart';

class BadgeEntity extends Equatable {
  const BadgeEntity({
    required this.category,
    required this.tier,
    required this.label,
    required this.info,
    required this.iconURL,
  });

  BadgeEntity copyWith({
    String? category,
    int? tier,
    String? label,
    String? info,
    String? iconURL,
  }) {
    return BadgeEntity(
      category: category ?? this.category,
      tier: tier ?? this.tier,
      label: label ?? this.label,
      info: info ?? this.info,
      iconURL: iconURL ?? this.iconURL,
    );
  }

  final String category;
  final int tier;
  final String label;
  final String info;
  final String iconURL;

  List<Object?> get props => [
    category,
    tier,
  ];
}
