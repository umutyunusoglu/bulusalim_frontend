import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/constants/configs/app_config.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/enums/event_role_enum.dart';
import 'package:bulusalim/core/utils/types/enums/user_event_status_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/event/event_model.dart';
import 'package:bulusalim/data/models/user/friend_model.dart';
import 'package:bulusalim/data/models/user/pinned_post_model.dart';
import 'package:bulusalim/data/models/user/user_event_model.dart';
import 'package:bulusalim/data/models/user/user_hobby_model.dart';
import 'package:bulusalim/data/models/user/user_model.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/user/friend_entity.dart';
import 'package:bulusalim/domain/entities/user/index.dart';
import 'package:bulusalim/domain/entities/user/pinned_post_entity.dart';
import 'package:bulusalim/domain/entities/user/user_event_entity.dart';
import 'package:bulusalim/domain/entities/user/user_hobby_entity.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/domain/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required FirebaseFirestore firestore,
    required LoggingService logger,
  }) : _firestore = firestore,
       _logger = logger;

  final FirebaseFirestore _firestore;
  final LoggingService _logger;
  final EventRepository eventRepository = getIt<EventRepository>();

  // === User CRUD ===
  @override
  Future<UserEntity?> getUser(Identifier userID) async {
    try {
      final uid = userID;

      final userDocSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!userDocSnapshot.exists) return null;

      final historySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('eventLog')
          .where('status', whereIn: ['upcoming', 'ongoing'])
          .orderBy('date')
          .get();

      final eventFutures = historySnapshot.docs.map((
        doc,
      ) async {
        final historyData = doc.data();
        final eventId = historyData['eventID'] as Identifier; // ID'yi al

        final eventDoc = await _firestore
            .collection('events')
            .doc(eventId)
            .get();

        if (!eventDoc.exists) return null;

        final eventEntity = EventModel.fromFirestore(
          eventDoc.data()!,
        ).toEntity();

        return eventEntity.copyWith(
          myStatus: historyData['status'].toString(),
          myRole: historyData['role'].toString(),
        );
      }).toList();

      final realActiveEvents = (await Future.wait(
        eventFutures,
      )).whereType<EventEntity>().toList();

      final hobbyList =
          (userDocSnapshot.data()?['hobbies'] as List<dynamic>?)
              ?.map((hobby) => hobby.toString())
              .toList() ??
          [];

      final userModel = await UserModel.fromFirestore(userDocSnapshot.data()!);

      return userModel.toEntity().copyWith(
        activeEvents: realActiveEvents,
        hobbies: hobbyList,
      );
    } on Exception catch (e) {
      _logger.error('User Repository Error: $e');
      return null;
    }
  }

  @override
  Future<void> createUser(
    UserEntity user,
  ) async {
    _logger.info('Creating user: ${user.userID}');

    final doc = _firestore.collection('users').doc();
    final userModel = UserModel.fromEntity(user.copyWith(userID: doc.id));

    await doc.set(userModel.toFirestore());
  }

  @override
  Future<void> deleteUser(Identifier userID) async {
    _logger.info('Deleting user: $userID');
    await _firestore.collection('users').doc(userID).delete();
  }

  @override
  Future<void> updateUser(
    Identifier userID,
    Map<String, dynamic> updates,
  ) async {
    _logger.info('Updating user: $userID');
    await _firestore.collection('users').doc(userID).update(updates);
  }

  // === Hobbies Subcollection ===
  @override
  Future<void> addHobby(
    Identifier userID,
    UserHobbyEntity hobby,
  ) async {
    _logger.info('Adding hobby for user: $userID');

    final hobbyModel = UserHobbyModel.fromEntity(hobby);
    await _firestore
        .collection('users')
        .doc(userID)
        .collection('hobbies')
        .doc(hobby.hobby.name)
        .set(hobbyModel.toFirestore());
  }

  @override
  Future<void> updateHobby(
    Identifier userID,
    String hobbyName,
    Map<String, dynamic> updates,
  ) async {
    _logger.info(
      'Updating hobby for user: $userID, hobby: $hobbyName',
    );
    await _firestore
        .collection('users')
        .doc(userID)
        .collection('hobbies')
        .doc(hobbyName)
        .update(updates);
  }

  @override
  Future<void> deleteHobby(
    Identifier userID,
    String hobbyName,
  ) async {
    _logger.info(
      'Deleting hobby for user: $userID, hobby: $hobbyName',
    );
    await _firestore
        .collection('users')
        .doc(userID)
        .collection('hobbies')
        .doc(hobbyName)
        .delete();
  }

  @override
  Future<List<UserHobbyEntity>> getUserHobbies(
    Identifier userID,
  ) async {
    _logger.info('Getting hobbies for user: $userID');
    final snapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('hobbies')
        .get();

    return snapshot.docs
        .map((doc) => UserHobbyModel.fromFirestore(doc.data()).toEntity())
        .toList();
  }

  // === Events Subcollection ===
  @override
  Future<void> addEvent(
    Identifier userID,
    UserEventEntity event,
  ) async {
    _logger.info('Adding event for user: $userID');

    final eventModel = UserEventModel.fromEntity(event);
    await _firestore
        .collection('users')
        .doc(userID)
        .collection('events')
        .doc(event.eventId)
        .set(eventModel.toFirestore());
  }

  @override
  Future<List<UserEventEntity>> getUserEventLog(
    Identifier userID,
  ) async {
    _logger.info('Getting events for user: $userID');
    final snapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('eventLog')
        .get();

    final events = snapshot.docs
        .map((doc) => UserEventModel.fromFirestore(doc.data()).toEntity())
        .toList();
    _logger.info(
      'Found events for user: $userID, events: $events',
    );
    return events;
  }

  @override
  Future<void> saveEvent(
    Identifier userID,
    EventEntity event,
  ) async {
    _logger.info('Saving event to user log for user: $userID');

    final userEvent = UserEventEntity(
      eventId: event.eventID,
      role: EventRoleEnum.fromString(event.currentUserRole ?? 'participant'),
      status: UserEventStatusEnum.saved,
      updatedAt: DateTime.now(),
    );

    final userEventModel = UserEventModel.fromEntity(userEvent);

    await _firestore
        .collection('users')
        .doc(userID)
        .collection('eventLog')
        .doc(event.eventID)
        .set(userEventModel.toFirestore());

    return;
  }

  @override
  Future<void> unSaveEvent(
    Identifier userID,
    Identifier eventID,
  ) async {
    _logger.info('Unsaving event from user log for user: $userID');
    final eventLogRef = _firestore
        .collection('users')
        .doc(userID)
        .collection('eventLog')
        .doc(eventID);

    final eventLogDoc = await eventLogRef.get();

    if (!eventLogDoc.exists) {
      _logger.info(
        'Event log entry does not exist for user: $userID and event: $eventID',
      );
      return;
    }

    final eventLog = UserEventModel.fromFirestore(eventLogDoc.data()!);

    if (eventLog.status != UserEventStatusEnum.saved) {
      _logger.info(
        'Event log entry is not saved for user: $userID and event: $eventID',
      );
      return;
    }

    await _firestore
        .collection('users')
        .doc(userID)
        .collection('eventLog')
        .doc(eventID)
        .delete();
  }

  @override
  Future<bool> isEventSaved(
    Identifier userID,
    Identifier eventID,
  ) async {
    _logger.info('Checking if event is saved for user: $userID');
    final eventLogRef = _firestore
        .collection('users')
        .doc(userID)
        .collection('eventLog')
        .doc(eventID);
    final eventLogDoc = await eventLogRef.get();
    if (!eventLogDoc.exists) return false;
    final eventLog = UserEventModel.fromFirestore(eventLogDoc.data()!);
    return eventLog.status == UserEventStatusEnum.saved;
  }

  @override
  Stream<List<EventEntity>> watchOngoingEvents(
    Identifier userID,
  ) {
    return _firestore
        .collection('users')
        .doc(userID)
        .collection('eventLog')
        .where('status', whereIn: ['ongoing']) // Sadece devam edenler
        .snapshots()
        .asyncMap((snapshot) async {
          _logger.info(
            'UserRepository: Ongoing events snapshot received for user: $userID, doc count: ${snapshot.docs.length}',
          );
          if (snapshot.docs.isEmpty) return [];

          // ID'leri alıp detayları çekme (Parallel Fetch)
          final eventFutures = snapshot.docs.map((doc) async {
            final historyData = doc.data();
            final eventId = historyData['eventID'] as Identifier;

            // Event detayını çek
            final eventDoc = await _firestore
                .collection('events')
                .doc(eventId)
                .get();
            if (!eventDoc.exists) return null;

            final eventEntity = await eventRepository.getEvent(eventId);
            if (eventEntity == null) return null;
            // Status ve Role bilgisini güncelle
            return eventEntity.copyWith(
              myStatus: historyData['status'] as String,
              myRole: historyData['role'].toString(),
            );
          });

          // Null olanları temizle ve listeyi döndür
          final events = await Future.wait(eventFutures);
          return events.whereType<EventEntity>().toList();
        });
  }

  @override
  Stream<List<EventEntity>> watchActiveEvents(
    Identifier userID,
  ) {
    return _firestore
        .collection('users')
        .doc(userID)
        .collection('eventLog')
        .where('status', whereIn: ['upcoming', 'ongoing']) // Sadece aktifler
        .orderBy('date')
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return [];

          // ID'leri alıp detayları çekme (Parallel Fetch)
          final eventFutures = snapshot.docs.map((doc) async {
            final historyData = doc.data();
            final eventId = historyData['eventID'] as Identifier;

            // Event detayını çek
            final eventDoc = await _firestore
                .collection('events')
                .doc(eventId)
                .get();
            if (!eventDoc.exists) return null;

            final eventEntity = EventModel.fromFirestore(
              eventDoc.data()!,
            ).toEntity();

            // Status ve Role bilgisini güncelle
            return eventEntity.copyWith(
              myStatus: historyData['status'] as String,
              myRole: historyData['role'].toString(),
            );
          });

          // Null olanları temizle ve listeyi döndür
          final events = await Future.wait(eventFutures);
          return events.whereType<EventEntity>().toList();
        });
  }

  @override
  Future<void> deleteEvent(
    Identifier userID,
    Identifier eventID,
  ) async {
    _logger.info(
      'Deleting event for user: $userID, event: $eventID',
    );
    await _firestore
        .collection('users')
        .doc(userID)
        .collection('events')
        .doc(eventID)
        .delete();
  }

  // Friendships Subcollection
  @override
  Future<void> addFollower(
    Identifier userID,
    Follower follower,
  ) async {
    _logger.info('Adding follower for user: $userID');

    final followerData = {
      'userID': follower.userID,
      'username': follower.username,
      'profileImageUrl': follower.profileImageUrl,
      'createdAt': Timestamp.fromDate(follower.createdAt),
    };

    await _firestore
        .collection('users')
        .doc(userID)
        .collection('followers')
        .doc(follower.userID)
        .set(followerData);
  }

  @override
  Future<void> removeFollower(
    Identifier userID,
    Identifier followerID,
  ) async {
    _logger.info('Removing follower for user: $userID');

    await _firestore
        .collection('users')
        .doc(userID)
        .collection('followers')
        .doc(followerID)
        .delete();
  }

  @override
  Future<void> addFollowee(
    Identifier userID,
    Followee followee,
  ) async {
    _logger.info('Adding followee for user: $userID');

    final followeeData = {
      'userID': followee.userID,
      'username': followee.username,
      'profileImageUrl': followee.profileImageUrl,
      'createdAt': Timestamp.fromDate(followee.createdAt),
    };

    await _firestore
        .collection('users')
        .doc(userID)
        .collection('followees')
        .doc(followee.userID)
        .set(followeeData);
  }

  @override
  Future<void> removeFollowee(
    Identifier userID,
    Identifier followeeID,
  ) async {
    _logger.info('Removing followee for user: $userID');

    await _firestore
        .collection('users')
        .doc(userID)
        .collection('followees')
        .doc(followeeID)
        .delete();
  }

  @override
  Future<bool> isFollowing(
    Identifier userID,
    Identifier otherUserID,
  ) async {
    _logger.info(
      'Checking if user: $userID is following user: $otherUserID',
    );

    final doc = await _firestore
        .collection('users')
        .doc(userID)
        .collection('followees')
        .doc(otherUserID)
        .get();

    return doc.exists;
  }

  @override
  Future<bool> isFollower(
    Identifier userID,
    Identifier otherUserID,
  ) async {
    _logger.info(
      'Checking if user: $userID is a follower of user: $otherUserID',
    );
    final doc = await _firestore
        .collection('users')
        .doc(userID)
        .collection('followers')
        .doc(otherUserID)
        .get();

    return doc.exists;
  }

  Future<List<Follower>> getFollowers(Identifier userID) async {
    _logger.info('Getting followers for user: $userID');

    final snapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('followers')
        .get();

    final followers = snapshot.docs.map((doc) {
      final data = doc.data();
      final friendModel = FriendModel.fromFirestore(data);
      return friendModel.toEntity();
    }).toList();

    return followers;
  }

  @override
  Future<List<Followee>> getFollowees(Identifier userID) async {
    _logger.info('Getting followees for user: $userID');

    final snapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('followees')
        .get();
    final followees = snapshot.docs.map((doc) {
      final data = doc.data();
      final friendModel = FriendModel.fromFirestore(data);
      return friendModel.toEntity();
    }).toList();

    return followees;
  }

  @override
  Future<void> sendFollowRequest(
    Identifier fromUserID,
    Identifier toUserID,
  ) async {
    _logger.info(
      'Sending follow request from user: $fromUserID to user: $toUserID',
    );

    final fromUser = await getUser(fromUserID);
    if (fromUser == null) {
      _logger.error('From user not found: $fromUserID');
      return;
    }

    await _firestore
        .collection('users')
        .doc(toUserID)
        .collection('followRequests')
        .doc(fromUserID)
        .set({
          'userID': fromUserID,
          'username': fromUser.username,
          'profileImageUrl': fromUser.profileImageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  Future<void> cancelFollowRequest(
    Identifier fromUserID,
    Identifier toUserID,
  ) async {
    _logger.info(
      'Cancelling follow request from user: $fromUserID to user: $toUserID',
    );

    await _firestore
        .collection('users')
        .doc(toUserID)
        .collection('followRequests')
        .doc(fromUserID)
        .delete();
  }

  @override
  Future<bool> hasSentFollowRequest(
    Identifier userID,
    Identifier otherUserID,
  ) async {
    _logger.info(
      'Checking if user: $userID has sent a follow request to user: $otherUserID',
    );

    final doc = await _firestore
        .collection('users')
        .doc(otherUserID)
        .collection('followRequests')
        .doc(userID)
        .get();

    return doc.exists;
  }

  // === Query & Search ===
  @override
  Future<List<UserEntity>> searchUsersByName(String name) async {
    _logger.info('Searching users by name: $name');

    final snapshot = await _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: name)
        .where('name', isLessThan: '$name\uf8ff')
        .get();

    final users = await Future.wait(
      snapshot.docs.map((doc) async {
        final model = await UserModel.fromFirestore(doc.data());
        return model.toEntity();
      }),
    );

    return users;
  }

  @override
  Future<List<UserEntity>> getUsersByOrg(String org) async {
    _logger.info('Getting users by organization: $org');

    final snapshot = await _firestore
        .collection('users')
        .where('organization', isEqualTo: org)
        .get();

    if (snapshot.docs.isEmpty) return [];

    final users = await Future.wait(
      snapshot.docs.map((doc) async {
        final model = await UserModel.fromFirestore(doc.data());
        return model.toEntity();
      }),
    );

    return users;
  }

  @override
  Future<List<UserPostEntity>> getPinnedPosts(Identifier userID) async {
    _logger.info('Getting pinned posts for user: $userID');
    final snapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('posts')
        .where('isPinned', isEqualTo: true)
        .get();

    final pinnedPosts = snapshot.docs.map(
      (doc) {
        final model = UserPostModel.fromFirestore(doc.data());
        return model.toEntity();
      },
    ).toList();

    return pinnedPosts;
  }

  Future<List<UserPostEntity>> getActivePosts(Identifier userID) async {
    _logger.info('Getting active posts for user: $userID');

    //Return posts which are created at most 1 day ago.

    final snapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('posts')
        .where(
          'createdAt',
          isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(
              const Duration(days: AppConfig.activePostDays),
            ),
          ),
        )
        .get();

    final activePosts = snapshot.docs.map(
      (doc) {
        final model = UserPostModel.fromFirestore(doc.data());
        return model.toEntity();
      },
    ).toList();
    return activePosts;
  }

  @override
  Future<List<UserPostEntity>> getUserPosts(Identifier userID) async {
    _logger.info('Getting user posts for user: $userID');
    final snapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('posts')
        .get();

    final posts = snapshot.docs.map(
      (doc) {
        final model = UserPostModel.fromFirestore(doc.data());
        return model.toEntity();
      },
    ).toList();

    return posts;
  }

  @override
  Future<List<UserEventEntity>?> getUserEventLogFiltered(
    Identifier userID,
    List<UserEventStatusEnum> statuses,
  ) {
    final statusStrings = statuses.map((e) => e.toString()).toList();

    _logger.info(
      'Getting filtered events for user: $userID with statuses: $statusStrings',
    );

    return _firestore
        .collection('users')
        .doc(userID)
        .collection('eventLog')
        .where('status', whereIn: statusStrings)
        .get()
        .then((snapshot) {
          final events = snapshot.docs
              .map((doc) => UserEventModel.fromFirestore(doc.data()).toEntity())
              .toList();

          _logger.info(
            'Found filtered events for user: $userID, events: $events',
          );
          return events;
        });
  }

  @override
  Future<void> updateUserEventLogStatus(
    Identifier userID,
    String eventID,
    String status,
  ) async {
    await _firestore
        .collection('users')
        .doc(userID)
        .collection('eventLog')
        .doc(eventID)
        .update({'status': status});
  }

  @override
  Future<void> updateFcmToken(
    Identifier userID,
    String fcmToken,
  ) async {
    await _firestore.collection('users').doc(userID).update({
      'fcmTokens': FieldValue.arrayUnion([fcmToken]),
    });
  }

  @override
  Future<void> removeFcmToken(
    Identifier userID,
    String fcmToken,
  ) async {
    await _firestore.collection('users').doc(userID).update({
      'fcmTokens': FieldValue.arrayRemove([fcmToken]),
    });
  }
}
