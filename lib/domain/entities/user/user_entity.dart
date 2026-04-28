import 'dart:isolate';

import 'package:equatable/equatable.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/core/utils/types/enums/capability.dart';
import 'package:outnest/core/utils/types/enums/gender_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.userID,
    required this.username,
    required this.nameSurname,
    required this.city,
    required this.birthDate,
    required this.gender,
    required this.university,
    required this.universityEmail,
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
    required this.capabilities,

    this.isPrivate = false,
    this.hideSavedEvents = false,
    this.hobbies = const [],
    this.followerIds = const [],
    this.followeeIds = const [],
    this.verifiedEventCount = 0,
  });

  UserEntity copyWith({
    Identifier? userID,
    String? email,
    String? nameSurname,
    String? username,
    String? city,
    DateTime? birthDate,
    GenderEnum? gender,
    String? university,
    String? universityEmail,
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
    int? verifiedEventCount,
    Set<CapabilityEnum>? capabilities,
  }) {
    return UserEntity(
      userID: userID ?? this.userID,
      username: username ?? this.username,
      nameSurname: nameSurname ?? this.nameSurname,
      city: city ?? this.city,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      university: university ?? this.university,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      accountType: accountType ?? this.accountType,
      communityData: communityData ?? this.communityData,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      hobbies: hobbies ?? this.hobbies,
      followeeCount: followeeCount ?? this.followeeCount,
      followerCount: followerCount ?? this.followerCount,
      isPrivate: isPrivate ?? this.isPrivate,
      universityEmail: universityEmail ?? this.universityEmail,
      hideSavedEvents: hideSavedEvents ?? this.hideSavedEvents,
      followerIds: followerIds ?? this.followerIds,
      followeeIds: followeeIds ?? this.followeeIds,
      verifiedEventCount: verifiedEventCount ?? this.verifiedEventCount,
      capabilities: capabilities ?? this.capabilities,
    );
  }

  final Identifier userID;
  final String username;
  final String nameSurname;
  final String? city;
  final DateTime birthDate;
  final String? phoneNumber;
  final GenderEnum gender;
  final String? university;
  final String? universityEmail;
  final String profileImageUrl;
  final String? bio;
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
  final int verifiedEventCount;

  final Set<CapabilityEnum> capabilities;

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
    communityData,
    accountType,
    phoneNumber,
    createdAt,
    updatedAt,
    lastActiveAt,
    followeeCount,
    followerCount,
    hobbies,
    followerIds,
    followeeIds,
    verifiedEventCount,
    capabilities,
  ];
}

class CommunityData extends Equatable {
  const CommunityData({
    required this.communityBio,
    required this.communityPhotoUrl,
    required this.communityTeamMembers,
    required this.instagramUrl,
    required this.whatsappUrl,
    required this.websiteUrl,
    required this.contactEmail,
  });
  factory CommunityData.fromMap(Map<String, dynamic> data) {
    final communityBio = data['communityBio'] as String? ?? '';
    final communityPhotoUrl = data['communityPhotoUrl'] as String? ?? '';
    final communityTeamMembers = <CompactUserEntity>[];

    if (data['communityTeamMembers'] != null) {
      final membersList = data['communityTeamMembers'] as List<dynamic>;
      for (final member in membersList) {
        if (member is Map) {
          communityTeamMembers.add(
            CompactUserEntity.fromMap(Map<String, dynamic>.from(member)),
          );
        }
      }
    }

    final instagramUrl = data['instagramUrl'] as String? ?? '';
    final whatsappUrl = data['whatsappUrl'] as String? ?? '';
    final websiteUrl = data['websiteUrl'] as String? ?? '';
    final contactEmail = data['contactEmail'] as String? ?? '';

    return CommunityData(
      communityBio: communityBio,
      communityPhotoUrl: communityPhotoUrl,
      communityTeamMembers: communityTeamMembers,
      instagramUrl: instagramUrl,
      whatsappUrl: whatsappUrl,
      websiteUrl: websiteUrl,
      contactEmail: contactEmail,
    );
  }

  CommunityData copyWith({
    String? communityBio,
    String? communityPhotoUrl,
    List<CompactUserEntity>? communityTeamMembers,
    String? instagramUrl,
    String? whatsappUrl,
    String? websiteUrl,
    String? contactEmail,
  }) {
    return CommunityData(
      communityBio: communityBio ?? this.communityBio,
      communityPhotoUrl: communityPhotoUrl ?? this.communityPhotoUrl,
      communityTeamMembers: communityTeamMembers ?? this.communityTeamMembers,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      whatsappUrl: whatsappUrl ?? this.whatsappUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      contactEmail: contactEmail ?? this.contactEmail,
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
      'contactEmail': contactEmail,
    };
  }

  final String communityPhotoUrl;
  final String communityBio;
  final List<CompactUserEntity> communityTeamMembers;
  final String? instagramUrl;
  final String? whatsappUrl;
  final String websiteUrl;
  final String contactEmail;

  @override
  List<Object?> get props => [
    communityBio,
    communityPhotoUrl,
    communityTeamMembers,
    instagramUrl,
    whatsappUrl,
    websiteUrl,
    contactEmail,
  ];
}
