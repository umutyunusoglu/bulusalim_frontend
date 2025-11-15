import 'package:bulusalim/application/providers/getIt_init.dart';
import 'package:bulusalim/core/constants/Configs/app_config.dart';
import 'package:bulusalim/core/utils/types/enums/gender_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:bulusalim/domain/services/file_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserModel extends Model<UserEntity> {
  UserModel({
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
  });

  @override
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      userID: entity.userID,
      email: entity.email,
      username: entity.username,
      birthDate: entity.birthDate,
      gender: entity.gender,
      organization: entity.organization,
      profileImageUrl: entity.profileImageUrl,
      bio: entity.bio,
      permissions: entity.permissions,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastActiveAt: entity.lastActiveAt,
    );
  }

  static Future<UserModel> fromFirestore(Map<String, dynamic> doc) async {
    late final String profileImageUrl;
    if (kDebugMode) {
      profileImageUrl = (doc['profileImageUrl'] as String).replaceAll(
        'localhost',
        AppConfig.host,
      );
    } else {
      profileImageUrl = doc['profileImageUrl'] as String;
    }
    return UserModel(
      userID: doc['userID'] as String,
      email: doc['email'] as String,
      username: doc['username'] as String,
      birthDate: (doc['birthDate'] as Timestamp).toDate(),
      gender: GenderEnum.values[doc['gender'] as int],
      organization: doc['organization'] as String,
      profileImageUrl: profileImageUrl,
      bio: doc['bio'] as String?,
      permissions: userPermissionsFromFirestore(
        doc['permissions'] as Map<String, dynamic>,
      ),
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
      updatedAt: (doc['updatedAt'] as Timestamp).toDate(),
      lastActiveAt: (doc['lastActiveAt'] as Timestamp).toDate(),
    );
  }

  static UserPermissions userPermissionsFromFirestore(
    Map<String, dynamic> doc,
  ) {
    return UserPermissions(
      locationEnabled: doc['locationEnabled'] as bool,
      notificationsEnabled: doc['notificationsEnabled'] as bool,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    profileImageUrl.replaceAll(
      AppConfig.host,
      'localhost',
    );
    return {
      'userID': userID,
      'email': email,
      'username': username,
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender.index,
      'organization': organization,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'permissions': permissions.toMap(),
    };
  }

  @override
  UserEntity toEntity() {
    return UserEntity(
      userID: userID,
      email: email,
      username: username,
      birthDate: birthDate,
      gender: gender,
      organization: organization,
      profileImageUrl: profileImageUrl,
      bio: bio,
      permissions: permissions,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastActiveAt: lastActiveAt,
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
}
