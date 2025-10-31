import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class HobbyEntity extends Equatable {
  const HobbyEntity({
    required this.name,
  });

  factory HobbyEntity.fromString(String hobby) {
    return HobbyEntity(
      name: hobby,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HobbyEntity && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'HobbyEntity(name: $name)';

  final String name;

  @override
  List<Object?> get props => [name];
}
