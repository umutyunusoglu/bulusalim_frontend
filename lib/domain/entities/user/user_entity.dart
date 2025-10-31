import 'package:bulusalim/core/utils/types/enums/gender_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/user/user_event_entity.dart';
import 'package:bulusalim/domain/entities/user/user_hobby_entity.dart';
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.birthDate,
    required this.gender,
    required this.organization,
    required this.profilePhotoUrls,
    required this.bio,
    required this.permissions,
    required this.metadata,
    this.hobbies = const [],
    this.events = const [],
  });

  UserEntity copyWith({
    Identifier? id,
    String? email,
    String? name,
    String? surname,
    String? username,
    DateTime? birthDate,
    GenderEnum? gender,
    String? organization,
    List<String>? profilePhotoUrls,
    String? avatarUrl,
    String? bio,
    UserPermissions? permissions,
    UserMetadata? metadata,
    List<UserHobbyEntity>? hobbies,
    List<UserEventEntity>? events,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      organization: organization ?? this.organization,
      profilePhotoUrls: profilePhotoUrls ?? this.profilePhotoUrls,
      bio: bio ?? this.bio,
      permissions: permissions ?? this.permissions,
      metadata: metadata ?? this.metadata,
      hobbies: hobbies ?? this.hobbies,
      events: events ?? this.events,
    );
  }

  final Identifier id;
  final String email;
  final String username;
  final DateTime birthDate;
  final GenderEnum gender;
  final String organization;
  final List<String>? profilePhotoUrls;
  final String? bio;
  final UserPermissions permissions;
  final UserMetadata metadata;

  final List<UserHobbyEntity> hobbies;
  final List<UserEventEntity> events;

  @override
  List<Object?> get props => [
    id,
  ];
}

class UserMetadata extends Equatable {
  const UserMetadata({
    required this.createdAt,
    required this.updatedAt,
    required this.lastActiveAt,
  });

  factory UserMetadata.fromMap(Map<String, dynamic> map) {
    final keys = [
      'createdAt',
      'updatedAt',
      'lastActiveAt',
      'locationEnabled',
      'notificationsEnabled',
    ];

    for (final key in keys) {
      if (!map.containsKey(key)) {
        throw Exception('Missing key: $key');
      }
    }
    return UserMetadata(
      createdAt: map['createdAt'] as DateTime,
      updatedAt: map['updatedAt'] as DateTime,
      lastActiveAt: map['lastActiveAt'] as DateTime,
    );
  }

  @override
  List<Object?> get props => [
    createdAt,
    updatedAt,
    lastActiveAt,
  ];

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastActiveAt': lastActiveAt,
    };
  }

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActiveAt;
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
