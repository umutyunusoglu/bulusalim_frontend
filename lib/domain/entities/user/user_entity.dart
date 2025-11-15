import 'package:bulusalim/core/utils/types/enums/gender_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/user/user_event_entity.dart';
import 'package:bulusalim/domain/entities/user/user_hobby_entity.dart';
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.userID,
    required this.username,
    required this.email,
    required this.birthDate,
    required this.gender,
    required this.organization,
    required this.profileImageUrl,
    required this.bio,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActiveAt,
    this.hobbies = const [],
    this.events = const [],
  });

  UserEntity copyWith({
    Identifier? userID,
    String? email,
    String? name,
    String? surname,
    String? username,
    DateTime? birthDate,
    GenderEnum? gender,
    String? organization,
    String? profileImageUrl,
    String? avatarUrl,
    String? bio,
    UserPermissions? permissions,
    List<UserHobbyEntity>? hobbies,
    List<UserEventEntity>? events,
  }) {
    return UserEntity(
      userID: userID ?? this.userID,
      email: email ?? this.email,
      username: username ?? this.username,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      organization: organization ?? this.organization,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastActiveAt: lastActiveAt,
      permissions: permissions ?? this.permissions,
      hobbies: hobbies ?? this.hobbies,
      events: events ?? this.events,
    );
  }

  final Identifier userID;
  final String email;
  final String username;
  final DateTime birthDate;
  final GenderEnum gender;
  final String organization;
  final String profileImageUrl;
  final String? bio;
  final UserPermissions permissions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActiveAt;

  final List<UserHobbyEntity> hobbies;
  final List<UserEventEntity> events;

  @override
  List<Object?> get props => [
    userID,
  ];
}

class UserPermissions extends Equatable {
  const UserPermissions({
    required this.locationEnabled,
    required this.notificationsEnabled,
  });
  factory UserPermissions.fromMap(Map<String, dynamic> map) {
    final keys = ['locationEnabled', 'notificationsEnabled'];
    for (final key in keys) {
      if (!map.containsKey(key)) {
        throw Exception('Missing key: $key');
      }
    }

    return UserPermissions(
      locationEnabled: map['locationEnabled'] as bool,
      notificationsEnabled: map['notificationsEnabled'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'locationEnabled': locationEnabled,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  @override
  List<Object?> get props => [
    locationEnabled,
    notificationsEnabled,
  ];

  final bool locationEnabled;
  final bool notificationsEnabled;
}
