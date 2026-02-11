import 'package:equatable/equatable.dart';
import 'package:outnest/core/utils/types/types.dart';

class CompactUserEntity extends Equatable {
  const CompactUserEntity({
    required this.userID,
    required this.username,
    required this.profileImageUrl,
    required this.university,
  });
  factory CompactUserEntity.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('university') == false) {
      map['university'] = null;
    }

    return CompactUserEntity(
      userID: map['userID'] as Identifier,
      username: map['username'] as String,
      profileImageUrl: map['profileImageUrl'] as String,
      university: map['university'] as String?,
    );
  }

  CompactUserEntity copyWith({
    Identifier? userID,
    String? username,
    String? profileImageUrl,
    String? university,
  }) {
    return CompactUserEntity(
      userID: userID ?? this.userID,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      university: university ?? this.university,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'university': university ?? '',
    };
  }

  @override
  List<Object?> get props => [userID];

  final Identifier userID;
  final String username;
  final String profileImageUrl;
  final String? university;
}
