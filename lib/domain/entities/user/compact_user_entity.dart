import 'package:equatable/equatable.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/core/utils/types/types.dart';

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
  });
  factory CompactUserEntity.fromMap(Map<String, dynamic> map) {
    if (!map.containsKey('university')) {
      map['university'] = null;
    }
    if (!map.containsKey('bio')) {
      map['bio'] = null;
    }

    if (!map.containsKey('isPrivate')) {
      map['isPrivate'] = null;
    }
    if(!map.containsKey('accountType')){
      map['accountType']='personal';
    }

    final nameSurname = map['nameSurname'] ?? map['fullname'];
    if (nameSurname != null) {
      map['nameSurname'] = nameSurname;
    } 

    return CompactUserEntity(
      userID: map['userID'] as Identifier,
      username: map['username'] as String,
      profileImageUrl: map['profileImageUrl'] as String,
      university: map['university'] as String?,
      nameSurname: map['nameSurname'] as String?,
      isPrivate: map['isPrivate'] as bool?,
      bio: map['bio'] as String?,
      accountType: AccountType.fromString(map['accountType'] as String);
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
  }) {
    return CompactUserEntity(
      userID: userID ?? this.userID,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      university: university ?? this.university,
      nameSurname: nameSurname ?? this.nameSurname,
      isPrivate: isPrivate ?? this.isPrivate,
      bio: bio ?? this.bio,
      accountType:accountType?? this.accountType,
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
      'accountType': accountType,
    };
  }

  @override
  List<Object?> get props => [userID];

  final Identifier userID;
  final String username;
  final String profileImageUrl;

  //For Profile
  final String? nameSurname;
  final bool? isPrivate;
  final String? bio;

  //University might not be verified
  final String? university;

  final AccountType accountType;
}
