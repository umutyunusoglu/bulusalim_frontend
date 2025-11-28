import 'package:bulusalim/core/constants/Configs/app_config.dart';
// GenderEnum importunun doğru olduğundan emin ol
import 'package:bulusalim/core/utils/types/enums/gender_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
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
    required this.hobbies,
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
      hobbies: entity.hobbies,
    );
  }

  static Future<UserModel> fromFirestore(Map<String, dynamic> doc) async {
    // 1. Güvenli profil resmi okuma (null kontrolü eklendi)
    late final String profileImageUrl;
    if (kDebugMode) {
      profileImageUrl = (doc['profileImageUrl'] as String? ?? '').replaceAll(
        'localhost',
        AppConfig.host,
      );
    } else {
      profileImageUrl = doc['profileImageUrl'] as String? ?? '';
    }

    final birthDate = (doc['birthDate'] as Timestamp? ?? Timestamp.now())
        .toDate();
    final createdAt = (doc['createdAt'] as Timestamp? ?? Timestamp.now())
        .toDate();
    final updatedAt = (doc['updatedAt'] as Timestamp? ?? Timestamp.now())
        .toDate();
    final lastActiveAt = (doc['lastActiveAt'] as Timestamp? ?? Timestamp.now())
        .toDate();

    final genderString = doc['gender'] as String? ?? 'other';

    GenderEnum gender;
    try {
      gender = GenderEnum.fromString(genderString);
    } catch (e) {
      gender = GenderEnum.other;
    }

    return UserModel(
      userID: doc['userID'] as String,
      email: doc['email'] as String? ?? '',
      username: doc['username'] as String? ?? 'Bilinmeyen Kullanıcı',
      birthDate: birthDate,
      gender: gender,
      organization: doc['organization'] as String? ?? '',
      profileImageUrl: profileImageUrl,
      bio: doc['bio'] as String?,
      permissions: userPermissionsFromFirestore(
        doc['permissions'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastActiveAt: lastActiveAt,
      hobbies: (doc['hobbies'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  static UserPermissions userPermissionsFromFirestore(
    Map<String, dynamic> doc,
  ) {
    // Bu yardımcı metodu da daha güvenli hale getirelim
    return UserPermissions(
      locationEnabled: doc['locationEnabled'] as bool? ?? false,
      notificationsEnabled: doc['notificationsEnabled'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    final profileImageUrlFirestore = profileImageUrl.replaceAll(
      AppConfig.host,
      'localhost',
    );
    return {
      'userID': userID,
      'email': email,
      'username': username,
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender.value, // DİKKAT: .index yerine .value ("male", "female")
      'organization': organization,
      'profileImageUrl': profileImageUrlFirestore,
      'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'permissions': permissions.toMap(),
      'hobbies': hobbies,
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
      hobbies: hobbies,
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

  final List<String> hobbies;
}
