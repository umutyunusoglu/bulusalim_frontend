import 'package:equatable/equatable.dart';
import 'package:outnest/core/utils/types/types.dart';

class CompactUserEntity extends Equatable {
  const CompactUserEntity({
    required this.userID,
    required this.username,
    required this.profileImageUrl,
    required this.university,
    required this.fullname,
    required this.isPrivate,
    required this.bio,
  });
  factory CompactUserEntity.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('university') == false) {
      map['university'] = null;
    }
    if (map.containsKey('bio') == false) {
      map['bio'] = null;
    }
    if (map.containsKey('nameSurname') == false) {
      map['nameSurname'] = null;
    }
    if (map.containsKey('isPrivate') == false) {
      map['isPrivate'] = null;
    }

    return CompactUserEntity(
      userID: map['userID'] as Identifier,
      username: map['username'] as String,
      profileImageUrl: map['profileImageUrl'] as String,
      university: map['university'] as String?,
      fullname: map['fullname'] as String?,
      isPrivate: map['isPrivate'] as bool?,
      bio: map['bio'] as String?,
    );
  }

  CompactUserEntity copyWith({
    Identifier? userID,
    String? username,
    String? profileImageUrl,
    String? university,
    String? fullname,
    bool? isPrivate,
    String? bio,
  }) {
    return CompactUserEntity(
      userID: userID ?? this.userID,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      university: university ?? this.university,
      fullname: fullname ?? this.fullname,
      isPrivate: isPrivate ?? this.isPrivate,
      bio: bio ?? this.bio,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'university': university ?? '',
      'fullname': fullname,
      'isPrivate': isPrivate,
      'bio': bio ?? '',
    };
  }

  @override
  List<Object?> get props => [userID];

  final Identifier userID;
  final String username;
  final String profileImageUrl;

  //For Profile
  final String? fullname;
  final bool? isPrivate;
  final String? bio;

  //University might not be verified
  final String? university;
}
