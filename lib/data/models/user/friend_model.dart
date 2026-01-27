import 'package:outnest/data/models/model.dart';
import 'package:outnest/domain/entities/user/friend_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendModel extends Model<FriendEntity> {
  FriendModel({
    required this.userID,
    required this.username,
    required this.profileImageUrl,
    required this.createdAt,
  });

  factory FriendModel.fromEntity(FriendEntity entity) {
    return FriendModel(
      userID: entity.userID,
      username: entity.username,
      profileImageUrl: entity.profileImageUrl,
      createdAt: entity.createdAt,
    );
  }

  factory FriendModel.fromFirestore(Map<String, dynamic> doc) {
    return FriendModel(
      userID: doc['userID'] as String,
      username: doc['username'] as String,
      profileImageUrl: doc['profileImageUrl'] as String,
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'userID': userID,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  FriendEntity toEntity() {
    return FriendEntity(
      userID: userID,
      username: username,
      profileImageUrl: profileImageUrl,
      createdAt: createdAt,
    );
  }

  final String userID;
  final String username;
  final String profileImageUrl;
  final DateTime createdAt;
}
