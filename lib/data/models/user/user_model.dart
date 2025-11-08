import 'package:bulusalim/application/providers/getIt_init.dart';
import 'package:bulusalim/core/utils/types/enums/gender_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:bulusalim/domain/services/file_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    required this.metadata,
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
      metadata: entity.metadata,
    );
  }

  static Future<UserModel> fromFirestore(Map<String, dynamic> doc) async {
    final fileService = getIt<FileService>();

    final profileUrl = await fileService.getDownloadUrl(
      doc['profileImagePath'] as String,
    );

    return UserModel(
      userID: doc['userID'] as String,
      email: doc['email'] as String,
      username: doc['username'] as String,
      birthDate: (doc['birthDate'] as Timestamp).toDate(),
      gender: GenderEnum.values[doc['gender'] as int],
      organization: doc['organization'] as String,
      profileImageUrl: profileUrl,
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
      'userID': userID,
      'email': email,
      'username': username,
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender.index,
      'organization': organization,
      'profileImagePath': FileService.userProfileImagePath(
        userID,
        'profile.jpg',
      ),
      'bio': bio,

      'permissions': permissions.toMap(),
      'metadata': metadata.toMap(),
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
      metadata: metadata,
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
  final UserMetadata metadata;
}
