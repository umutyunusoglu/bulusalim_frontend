import 'package:outnest/domain/entities/hobby/hobby_entity.dart';
import 'package:equatable/equatable.dart';

class UserHobbyEntity extends Equatable {
  const UserHobbyEntity({
    required this.hobby,
    required this.level,
    required this.eventsJoined,
    required this.rating,
  });

  @override
  List<Object?> get props => [
    hobby,
    level,
    eventsJoined,
    rating,
  ];

  UserHobbyEntity copyWith({
    HobbyEntity? hobby,
    int? eventsJoined,
    double? rating,
    int? level,
  }) {
    return UserHobbyEntity(
      hobby: hobby ?? this.hobby,
      eventsJoined: eventsJoined ?? this.eventsJoined,
      rating: rating ?? this.rating,
      level: level ?? this.level,
    );
  }

  final HobbyEntity hobby;
  final int eventsJoined;
  final double rating;
  final int level;
}
