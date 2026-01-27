import 'package:outnest/data/models/model.dart';
import 'package:outnest/domain/entities/hobby/hobby_entity.dart';
import 'package:outnest/domain/entities/user/user_hobby_entity.dart';

class UserHobbyModel extends Model<UserHobbyEntity> {
  UserHobbyModel({
    required this.hobby,
    required this.level,
    required this.eventsJoined,
    required this.rating,
  });

  @override
  factory UserHobbyModel.fromEntity(UserHobbyEntity entity) {
    return UserHobbyModel(
      hobby: entity.hobby,
      level: entity.level,
      eventsJoined: entity.eventsJoined,
      rating: entity.rating,
    );
  }

  @override
  factory UserHobbyModel.fromFirestore(Map<String, dynamic> doc) {
    return UserHobbyModel(
      hobby: HobbyEntity(name: doc['hobby'] as String),
      level: doc['level'] as int,
      eventsJoined: doc['eventsJoined'] as int,
      rating: (doc['rating'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'hobby': hobby.name,
      'level': level,
      'eventsJoined': eventsJoined,
      'rating': rating,
    };
  }

  @override
  UserHobbyEntity toEntity() {
    return UserHobbyEntity(
      hobby: hobby,
      level: level,
      eventsJoined: eventsJoined,
      rating: rating,
    );
  }

  final HobbyEntity hobby;
  final int eventsJoined;
  final double rating;
  final int level;
}
