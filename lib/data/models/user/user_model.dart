import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
// GenderEnum importunun doğru olduğundan emin ol
import 'package:outnest/core/utils/types/enums/gender_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/data/models/model.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';

class UserModel extends Model<UserEntity> {
  UserModel({
    required this.userID,
    required this.username,
    required this.nameSurname,
    required this.birthDate,
    required this.gender,
    required this.university,
    required this.universityEmail,
    required this.isUniversityVerified,
    required this.profileImageUrl,
    required this.bio,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActiveAt,
    required this.hobbies,
    required this.followeeCount,
    required this.followerCount,
    required this.isPrivate,
    required this.hideSavedEvents,
    required this.phoneNumber,
    required this.accountType,
    required this.communityData,
  });

  @override
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      userID: entity.userID,
      nameSurname: entity.nameSurname,
      username: entity.username,
      birthDate: entity.birthDate,
      gender: entity.gender,
      university: entity.university,
      universityEmail: entity.universityEmail,
      isUniversityVerified: entity.isUniversityVerified,
      profileImageUrl: entity.profileImageUrl,
      bio: entity.bio,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastActiveAt: entity.lastActiveAt,
      hobbies: entity.hobbies,
      followeeCount: entity.followeeCount,
      followerCount: entity.followerCount,
      isPrivate: entity.isPrivate,
      hideSavedEvents: entity.hideSavedEvents,
      phoneNumber: entity.phoneNumber,
      accountType: entity.accountType,
      communityData: entity.communityData,
    );
  }

  static Future<UserModel> fromFirestore(Map<String, dynamic> doc) async {
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
      nameSurname: doc['nameSurname'] as String? ?? 'Bilinmeyen Kullanıcı',
      username: doc['username'] as String? ?? 'Bilinmeyen Kullanıcı',

      birthDate: birthDate,
      gender: gender,
      university: doc['universityName'] as String?,
      universityEmail: doc['universityEmail'] as String?,
      isUniversityVerified: doc['isUniversityVerified'] as bool? ?? false,
      profileImageUrl: doc['profileImageUrl'] as String? ?? '',
      bio: doc['bio'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastActiveAt: lastActiveAt,
      hobbies: (doc['hobbies'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      followeeCount: doc['followeeCount'] as int? ?? 0,
      followerCount: doc['followerCount'] as int? ?? 0,
      isPrivate: doc['isPrivate'] as bool? ?? false,
      hideSavedEvents: doc['hideSavedEvents'] as bool? ?? false,
      phoneNumber: doc['phoneNumber'] as String?,
      accountType: AccountType.fromString(
        doc['accountType'] as String? ?? 'personal',
      ),
      communityData: doc['communityData'] != null
          ? CommunityData.fromMap(doc['communityData'] as Map<String, dynamic>)
          : null,
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
      'username': username,
      'nameSurname': nameSurname,
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender.toString(),
      'universityName': university,
      'universityEmail': universityEmail,
      'isUniversityVerified': isUniversityVerified,
      'profileImageUrl': profileImageUrlFirestore,
      'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'hobbies': hobbies,
      'followeeCount': followeeCount,
      'followerCount': followerCount,
      'isPrivate': isPrivate,
      'hideSavedEvents': hideSavedEvents,
      'phoneNumber': phoneNumber,
      'accountType': accountType.toString(),
      'communityData': communityData?.toMap(),
    };
  }

  @override
  UserEntity toEntity() {
    return UserEntity(
      userID: userID,
      username: username,
      nameSurname: nameSurname,
      birthDate: birthDate,
      gender: gender,
      university: university,
      universityEmail: universityEmail,
      isUniversityVerified: isUniversityVerified,
      profileImageUrl: profileImageUrl,
      bio: bio,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastActiveAt: lastActiveAt,
      hobbies: hobbies,
      followeeCount: followeeCount,
      followerCount: followerCount,
      isPrivate: isPrivate,
      hideSavedEvents: hideSavedEvents,
      phoneNumber: phoneNumber,
      accountType: accountType,
      communityData: communityData,
    );
  }

  final Identifier userID;
  final String username;
  final String nameSurname;
  final DateTime birthDate;
  final GenderEnum gender;
  final String? university;
  final String? universityEmail;
  final bool isUniversityVerified;
  final String profileImageUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActiveAt;
  final int followeeCount;
  final int followerCount;
  final bool isPrivate;
  final bool hideSavedEvents;
  final String? phoneNumber;
  final AccountType accountType;
  final CommunityData? communityData;

  final List<String> hobbies;
}
