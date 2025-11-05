import 'package:bulusalim/core/utils/types/enums/gender_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends Model<UserEntity> {
  UserModel({
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
  });

  @override
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      username: entity.username,
      birthDate: entity.birthDate,
      gender: entity.gender,
      organization: entity.organization,
      profilePhotoUrls: entity.profileImagePaths,
      bio: entity.bio,
      permissions: entity.permissions,
      metadata: entity.metadata,
    );
  }

  @override
  factory UserModel.fromFirestore(Map<String, dynamic> doc) {
    return UserModel(
      id: doc['id'] as String,
      email: doc['email'] as String,
      username: doc['username'] as String,
      birthDate: (doc['birthDate'] as Timestamp).toDate(),
      gender: GenderEnum.values[doc['gender'] as int],
      organization: doc['organization'] as String,
      profilePhotoUrls: (doc['profilePhotoUrls'] as List<dynamic>?)
          ?.map((url) => url as String)
          .toList(),
      bio: doc['bio'] as String?,
      permissions: userPermissionsFromFirestore(
        doc['permissions'] as Map<String, dynamic>,
      ),
      metadata: userMetadataFromFirestore(
        doc['metadata'] as Map<String, dynamic>,
      ),
    );
  }

  static UserMetadata userMetadataFromFirestore(Map<String, dynamic> doc) {
    return UserMetadata(
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
    return {
      'id': id,
      'email': email,
      'username': username,
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender.index,
      'organization': organization,
      'profilePhotoUrls': profilePhotoUrls,
      'bio': bio,
      'permissions': permissions.toMap(),
      'metadata': metadata.toMap(),
    };
  }

  @override
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      username: username,
      birthDate: birthDate,
      gender: gender,
      organization: organization,
      profileImagePaths: profilePhotoUrls,
      bio: bio,
      permissions: permissions,
      metadata: metadata,
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
}
