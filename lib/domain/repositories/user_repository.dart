import 'package:bulusalim/core/utils/types/enums/user_event_status_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/user/friend_entity.dart';
import 'package:bulusalim/domain/entities/user/index.dart';
import 'package:bulusalim/domain/entities/user/pinned_post_entity.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:bulusalim/domain/entities/user/user_event_entity.dart';
import 'package:bulusalim/domain/entities/user/user_hobby_entity.dart';

abstract class UserRepository {
  // === User CRUD ===
  Future<UserEntity?> getUser(Identifier userID);
  Future<void> createUser(UserEntity user);
  Future<void> updateUser(
    Identifier userID,
    Map<String, dynamic> updates,
  );
  Future<void> deleteUser(Identifier userID);

  // === Hobbies Subcollection ===
  Future<void> addHobby(
    Identifier userID,
    UserHobbyEntity hobby,
  );
  Future<void> updateHobby(
    Identifier userID,
    String hobbyName,
    Map<String, dynamic> updates,
  );
  Future<void> deleteHobby(
    Identifier userID,
    String hobbyName,
  );

  // === Events Subcollection ===
  Future<void> addEvent(
    Identifier userID,
    UserEventEntity event,
  );
  Future<List<UserEventEntity>> getUserEventLog(
    Identifier userID,
  );

  Future<List<UserEventEntity>?> getUserEventLogFiltered(
    Identifier userID,
    List<UserEventStatusEnum> statuses,
  );

  Future<void> saveEvent(
    Identifier userID,
    EventEntity event,
  );

  Future<void> unSaveEvent(
    Identifier userID,
    Identifier eventID,
  );

  Future<bool> isEventSaved(
    Identifier userID,
    Identifier eventID,
  );

  Stream<List<EventEntity>> watchActiveEvents(Identifier userID);
  Stream<List<EventEntity>> watchOngoingEvents(Identifier userID);

  Future<void> deleteEvent(
    Identifier userID,
    Identifier eventID,
  );

  // === Pinned Posts Subcollection ===
  Future<List<UserPostEntity>> getPinnedPosts(Identifier userID);

  Future<List<UserPostEntity>> getUserPosts(Identifier userID);

  // Hobbies Subcollection
  Future<List<UserHobbyEntity>> getUserHobbies(
    Identifier userID,
  );

  // Friendships Subcollection
  Future<void> addFollower(
    Identifier userID,
    Follower follower,
  );
  Future<void> removeFollower(
    Identifier userID,
    Identifier followerID,
  );
  Future<void> addFollowee(
    Identifier userID,
    Followee followee,
  );
  Future<void> removeFollowee(
    Identifier userID,
    Identifier followeeID,
  );

  Future<bool> isFollowing(
    Identifier userID,
    Identifier otherUserID,
  );

  Future<bool> isFollower(
    Identifier userID,
    Identifier otherUserID,
  );

  Future<List<Follower>> getFollowers(Identifier userID);
  Future<List<Followee>> getFollowees(Identifier userID);

  Future<void> sendFollowRequest(
    Identifier fromUserID,
    Identifier toUserID,
  );
  Future<void> cancelFollowRequest(
    Identifier fromUserID,
    Identifier toUserID,
  );
  Future<bool> hasSentFollowRequest(
    Identifier fromUserID,
    Identifier toUserID,
  );

  // === Query & Search ===
  Future<List<UserEntity>> searchUsersByName(String name);
  Future<List<UserEntity>> getUsersByOrg(String org);

  // FMC Token Management
  Future<void> updateFcmToken(
    Identifier userID,
    String fcmToken,
  );
  Future<void> removeFcmToken(
    Identifier userID,
    String fcmToken,
  );

  Future<void> updateUserEventLogStatus(
    Identifier userID,
    String eventID,
    String status,
  );
}
