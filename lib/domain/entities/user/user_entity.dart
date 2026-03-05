import 'package:equatable/equatable.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/core/utils/types/enums/gender_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.userID,
    required this.username,
    required this.nameSurname,
    required this.email,
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
    required this.followeeCount,
    required this.followerCount,
    required this.communityData,
    required this.accountType,
    required this.phoneNumber,
    required this.instagram,

    this.isPrivate = false,
    this.hideSavedEvents = false,
    this.hobbies = const [],
    this.followerIds = const [],
    this.followeeIds = const [],
  });

  UserEntity copyWith({
    Identifier? userID,
    String? email,
    String? nameSurname,
    String? username,
    DateTime? birthDate,
    GenderEnum? gender,
    String? university,
    String? universityEmail,
    bool? isUniversityVerified,
    String? profileImageUrl,
    String? bio,
    String? phoneNumber,
    String? instagram,
    AccountType? accountType,
    CommunityData? communityData,
    List<String>? hobbies,
    int? followeeCount,
    int? followerCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
    bool? isPrivate,
    bool? hideSavedEvents,
    List<EventEntity>? activeEvents,
    List<Identifier>? followerIds,
    List<Identifier>? followeeIds,
  }) {
    return UserEntity(
      userID: userID ?? this.userID,
      email: email ?? this.email,
      username: username ?? this.username,
      nameSurname: nameSurname ?? this.nameSurname,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      university: university ?? this.university,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      instagram: instagram ?? this.instagram,
      accountType: accountType ?? this.accountType,
      communityData: communityData ?? this.communityData,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      hobbies: hobbies ?? this.hobbies,
      followeeCount: followeeCount ?? this.followeeCount,
      followerCount: followerCount ?? this.followerCount,
      isPrivate: isPrivate ?? this.isPrivate,
      universityEmail: universityEmail ?? this.universityEmail,
      isUniversityVerified: isUniversityVerified ?? this.isUniversityVerified,
      hideSavedEvents: hideSavedEvents ?? this.hideSavedEvents,
      followerIds: followerIds ?? this.followerIds,
      followeeIds: followeeIds ?? this.followeeIds,
    );
  }

  final Identifier userID;
  final String email;
  final String username;
  final String nameSurname;
  final DateTime birthDate;
  final String? phoneNumber;
  final GenderEnum gender;
  final String? university;
  final String? universityEmail;
  final bool isUniversityVerified;
  final String profileImageUrl;
  final String? bio;
  final String? instagram;
  final AccountType accountType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActiveAt;
  final int followeeCount;
  final int followerCount;
  final CommunityData? communityData;
  final List<String> hobbies;
  final bool isPrivate;
  final bool hideSavedEvents;

  final List<Identifier>? followerIds;
  final List<Identifier>? followeeIds;

  @override
  List<Object?> get props => [
    userID,
    username,
    nameSurname,
    profileImageUrl,
    bio,
    gender,
    birthDate,
    university,
    isPrivate,
    hideSavedEvents,
  ];
}

class CommunityData {
  CommunityData({
    required this.communityBio,
    required this.communityPhotoUrl,
    required this.communityTeamMembers,
    required this.instagramUrl,
    required this.whatsappUrl,
    required this.websiteUrl,
  });

  factory CommunityData.fromMap(Map<String, dynamic> data) {
    final communityBio = data['communityBio'] as String? ?? '';
    final communityPhotoUrl = data['communityPhotoUrl'] as String? ?? '';
    final communityTeamMembers = <CompactUserEntity>[];

    if (data['communityTeamMembers'] != null) {
      final membersList = data['communityTeamMembers'] as List<dynamic>;
      for (final member in membersList) {
        if (member is Map<String, dynamic>) {
          communityTeamMembers.add(CompactUserEntity.fromMap(member));
        }
      }
    }

    final instagramUrl = data['instagramUrl'] as String? ?? '';
    final whatsappUrl = data['whatsappUrl'] as String? ?? '';
    final websiteUrl = data['websiteUrl'] as String? ?? '';

    return CommunityData(
      communityBio: communityBio,
      communityPhotoUrl: communityPhotoUrl,
      communityTeamMembers: communityTeamMembers,
      instagramUrl: instagramUrl,
      whatsappUrl: whatsappUrl,
      websiteUrl: websiteUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'communityBio': communityBio,
      'communityPhotoUrl': communityPhotoUrl,
      'communityTeamMembers': communityTeamMembers
          .map((e) => e.toMap())
          .toList(),
      'instagramUrl': instagramUrl,
      'whatsappUrl': whatsappUrl,
      'websiteUrl': websiteUrl,
    };
  }

  final String communityPhotoUrl;
  final String communityBio;
  final List<CompactUserEntity> communityTeamMembers;
  final String? instagramUrl;
  final String? whatsappUrl;
  final String websiteUrl;
}
