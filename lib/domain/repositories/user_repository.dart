import 'package:outnest/core/utils/types/enums/user_event_status_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/friend_entity.dart';
import 'package:outnest/domain/entities/user/index.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/entities/user/user_event_entity.dart';
import 'package:outnest/domain/entities/user/user_hobby_entity.dart';

abstract class UserRepository {
  // === User CRUD ===
  Future<UserEntity?> getCurrentUser(Identifier userID);
  Future<CompactUserEntity?> getUserPublicData(Identifier userID);
  Stream<UserEntity?> watchUser(String id);
  Future<void> createUser(UserEntity user);
  Future<void> updateUser(
    Identifier userID,
    Map<String, dynamic> updates,
  );
  Future<void> deleteUser(String? reason);
  Future<bool> isUserRegistered(String userID);

  Future<bool> tryUpdateUsername(String newUsername, String userId);
  Future<bool> doesUsernameExist(String username);

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
  Stream<List<EventEntity>> watchCompletedAndActiveEvents(Identifier userID);
  Stream<List<EventEntity>> watchOngoingEvents(Identifier userID);
  Stream<List<EventEntity>> watchUpcomingEvents(Identifier userID);
  Stream<List<EventEntity>> watchPendingEvents(Identifier userID);

  Stream<List<CompactUserEntity>> watchFollowees(Identifier userID);
  Stream<List<CompactUserEntity>> watchFollowers(Identifier userID);
  Stream<List<CompactUserEntity>> watchBlockedUsers(Identifier userID);

  Stream<List<UserEventEntity>> watchUserEventLog(Identifier userID);

  Stream<List<PostEntity>> getUserPostsStream(String userId);

  Future<int> getCompletedEventCount(Identifier userID);

  Future<void> deleteEvent(
    Identifier userID,
    Identifier eventID,
  );

  // === Pinned Posts Subcollection ===
  Future<List<PostEntity>> getPinnedPosts(Identifier userID);

  Future<List<PostEntity>> getUserPosts(Identifier userID);

  // User Progress Subcollection
  Future<int> getUserProgress(Identifier userID, String category);

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

  Future<int> getFollowersCount(Identifier userID);
  Future<int> getFolloweesCount(Identifier userID);

  Future<List<Follower>> getFollowers(Identifier userID);
  Future<List<Followee>> getFollowees(Identifier userID);

  Future<List<Identifier>> getCommonFollowerIds(
    Identifier userID,
    List<Identifier> candidateIds,
  );

  Future<bool> isFollowRequestPending(String fromUserID, String toUserID);

  Future<void> sendFollowRequest(
    Identifier fromUserID,
    Identifier toUserID,
    bool fromNotification,
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

  Future<void> sendVerificationEmail(String email);
  Future<bool> verifyEmail(String email, String universityName, String code);
}
