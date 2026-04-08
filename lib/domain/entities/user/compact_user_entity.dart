import 'package:equatable/equatable.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/user/index.dart';

class CompactUserEntity extends Equatable {
  const CompactUserEntity({
    required this.userID,
    required this.username,
    required this.profileImageUrl,
    required this.university,
    required this.nameSurname,
    required this.isPrivate,
    required this.bio,
    required this.accountType,
    required this.communityData,
    this.verifiedEventCount = 0,
  });
  factory CompactUserEntity.fromMap(Map<String, dynamic> map) {
    return CompactUserEntity(
      // Eğer Identifier tipi de null gelebiliyorsa, buraya da müdahale etmek gerekebilir.
      userID: map['userID'] as Identifier,

      // Eğer bu alanlar null gelebiliyorsa, 'as String' patlar.
      // Güvenli olması için 'as String?' yapıp default bir boş değer atamak en iyisidir.
      username: map['username'] as String? ?? '',
      profileImageUrl: map['profileImageUrl'] as String? ?? '',

      university: map['university'] as String?,
      nameSurname: (map['nameSurname'] ?? map['fullname']) as String?,
      isPrivate: map['isPrivate'] as bool?,
      bio: map['bio'] as String?,

      accountType: AccountType.fromString(
        map['accountType'] as String? ?? 'personal',
      ),
      communityData: map['communityData'] != null
          ? CommunityData.fromMap(
              map['communityData'] as Map<String, dynamic>,
            )
          : null,
      verifiedEventCount: map['verifiedEventCount'] as int? ?? 0,
    );
  }

  CompactUserEntity copyWith({
    Identifier? userID,
    String? username,
    String? profileImageUrl,
    String? university,
    String? nameSurname,
    bool? isPrivate,
    String? bio,
    AccountType? accountType,
    CommunityData? communityData,
    int? verifiedEventCount,
  }) {
    return CompactUserEntity(
      userID: userID ?? this.userID,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      university: university ?? this.university,
      nameSurname: nameSurname ?? this.nameSurname,
      isPrivate: isPrivate ?? this.isPrivate,
      bio: bio ?? this.bio,
      accountType: accountType ?? this.accountType,
      communityData: communityData ?? this.communityData,
      verifiedEventCount: verifiedEventCount ?? this.verifiedEventCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'university': university ?? '',
      'nameSurname': nameSurname,
      'isPrivate': isPrivate,
      'bio': bio ?? '',
      'accountType': accountType.toString(),
      'verifiedEventCount': verifiedEventCount,
    };
  }

  @override
  List<Object?> get props => [
    userID,
    username,
    profileImageUrl,
    university,
    nameSurname,
    isPrivate,
    bio,
    accountType,
    communityData,
  ];

  final Identifier userID;
  final String username;
  final String profileImageUrl;

  //For Profile
  final String? nameSurname;
  final bool? isPrivate;
  final String? bio;

  //University might not be verified
  final String? university;

  final AccountType? accountType;
  final CommunityData? communityData;
  final int verifiedEventCount;
}
