import 'package:bulusalim/core/utils/types/types.dart';
import 'package:equatable/equatable.dart';

class FriendEntity with EquatableMixin {
  const FriendEntity({
    required this.userID,
    required this.username,
    required this.profileImageUrl,
    required this.createdAt,
  });

  FriendEntity copyWith({
    Identifier? userID,
    String? username,
    String? profileImageUrl,
    DateTime? createdAt,
  }) {
    return FriendEntity(
      userID: userID ?? this.userID,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [userID];

  final Identifier userID;
  final String username;
  final String profileImageUrl;
  final DateTime createdAt;
}

typedef Followee = FriendEntity;
typedef Follower = FriendEntity;
