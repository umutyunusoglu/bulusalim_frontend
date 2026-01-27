import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/core/utils/types/enums/gender_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:equatable/equatable.dart';

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
    required this.activeEvents,

    required this.accountType,
    required this.phoneNumber,
    required this.instagram,

    this.isPrivate = false,
    this.hideSavedEvents = false,
    this.hobbies = const [],
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
    String? avatarUrl,
    String? bio,
    String? phoneNumber,
    String? instagram,
    AccountType? accountType,

    List<String>? hobbies,
    int? followeeCount,
    int? followerCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
    bool? isPrivate,
    bool? hideSavedEvents,
    List<EventEntity>? activeEvents,
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
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      hobbies: hobbies ?? this.hobbies,
      followeeCount: followeeCount ?? this.followeeCount,
      followerCount: followerCount ?? this.followerCount,
      isPrivate: isPrivate ?? this.isPrivate,
      universityEmail: universityEmail ?? this.universityEmail,
      isUniversityVerified: isUniversityVerified ?? this.isUniversityVerified,
      activeEvents: activeEvents ?? this.activeEvents,
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
  final List<EventEntity> activeEvents;
  final List<String> hobbies;
  final bool isPrivate;
  final bool hideSavedEvents;

  @override
  List<Object?> get props => [
    userID,
  ];
}
