import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/event_role_enum.dart';
import 'package:outnest/core/utils/types/enums/user_event_status_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/data/models/event/event_model.dart';
import 'package:outnest/data/models/user/friend_model.dart';
import 'package:outnest/data/models/user/pinned_post_model.dart' hide getIt;
import 'package:outnest/data/models/user/user_event_model.dart';
import 'package:outnest/data/models/user/user_hobby_model.dart';
import 'package:outnest/data/models/user/user_model.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/friend_entity.dart';
import 'package:outnest/domain/entities/user/index.dart';
import 'package:outnest/domain/entities/user/pinned_post_entity.dart';
import 'package:outnest/domain/entities/user/user_event_entity.dart';
import 'package:outnest/domain/entities/user/user_hobby_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/services/session_service.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required FirebaseFirestore firestore,
    required LoggingService logger,
    required FirebaseFunctions functions,
  }) : _firestore = firestore,
       _logger = logger,
       _functions = functions;

  final FirebaseFirestore _firestore;
  final LoggingService _logger;
  final FirebaseFunctions _functions;
  final EventRepository eventRepository = getIt<EventRepository>();

  // === User CRUD ===
  @override
  Future<UserEntity?> getCurrentUser(Identifier userID) async {
    try {
      final uid = userID;

      final currentUserID = getIt<SessionService>().currentUser?.userID;
      if (currentUserID == null) {
        return null;
      }

      if (currentUserID != uid) {
        throw Exception("You can't access other people's data!");
      }

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
  Future<CompactUserEntity?> getUserPublicData(Identifier userID) async {
    try {
      // await kullanarak verinin gelmesini bekliyoruz
      final doc = await _firestore
          .collection('public_users')
          .doc(userID.toString())
          .get();

      if (!doc.exists) {
        _logger.info('Public user not found: $userID');
        return null;
      }

      final data = doc.data();
      if (data == null) return null;

      return CompactUserEntity.fromMap(data);
    } catch (e) {
      _logger.error(
        'Error fetching/parsing public user data for userID: $userID, error: $e',
      );
      return null;
    }
  }

  @override
  Stream<UserEntity?> watchUser(Identifier userID) {
    final uid = userID;

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots() // 1. Dinlemeyi başlatıyoruz
        .asyncMap((userDocSnapshot) async {
          // 2. Her update geldiğinde ASYNC işlem yapıyoruz

          try {
            if (!userDocSnapshot.exists) return null;

            // --- BURASI ESKİ KODUNUN AYNISI (Event Log Fetching) ---
            final historySnapshot = await _firestore
                .collection('users')
                .doc(uid)
                .collection('eventLog')
                .where('status', whereIn: ['upcoming', 'ongoing'])
                .orderBy('date')
                .get(); // DİKKAT: Burası hala 'get', yani eventLog değişirse stream tetiklenmez!

            final eventFutures = historySnapshot.docs.map((doc) async {
              final historyData = doc.data();
              final eventId = historyData['eventID'] as Identifier;

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

            // --- HOBBY LIST ---
            final hobbyList =
                (userDocSnapshot.data()?['hobbies'] as List<dynamic>?)
                    ?.map((hobby) => hobby.toString())
                    .toList() ??
                [];

            // --- MODEL OLUŞTURMA ---
            final userModel = await UserModel.fromFirestore(
              userDocSnapshot.data()!,
            );

            return userModel.toEntity().copyWith(
              activeEvents: realActiveEvents,
              hobbies: hobbyList,
            );
          } catch (e) {
            // Stream içinde hata olursa logla ve null dön (veya hatayı fırlat)
            _logger.error('User Repository Stream Error: $e');
            return null;
          }
        });
  }

  @override
  Future<void> createUser(UserEntity user) async {
    _logger.info(
      'Creating user: ${user.userID} with username: ${user.username}',
    );

    // Sorgulama yapabilmek için username'in küçük harf versiyonu şart

    return _firestore.runTransaction((transaction) async {
      // 1. ADIM: Username daha önce alınmış mı kontrol et
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: user.username)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        _logger.warn('Username already taken: ${user.username}');
        throw Exception('username-already-exists');
        // UI tarafında bu hatayı yakalayıp "Bu isim alınmış" diyebilirsin.
      }

      // 2. ADIM: Yeni doküman referansını al
      // Eğer Auth'tan gelen bir UID varsa onu kullanmak daha mantıklıdır (user.userID)
      final docRef = _firestore.collection('users').doc(user.userID);

      final userModel = UserModel.fromEntity(user);
      final userData = userModel.toFirestore();
      userData['registerCompleted'] = true;

      // 4. ADIM: Kaydı gerçekleştir
      transaction.set(docRef, userData, SetOptions(merge: true));

      _logger.info('User successfully created with unique username');
    });
  }

  @override
  Future<bool> tryUpdateUsername(String newUsername, String userId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // 1. ADIM: SORGULA (Transaction içinde)
        final snapshot = await _firestore
            .collection('users')
            .where('username', isEqualTo: newUsername)
            .get();

        // Eğer isim başkası tarafından alınmışsa işlemi iptal et
        if (snapshot.docs.isNotEmpty && snapshot.docs.first.id != userId) {
          return false;
        }

        // 2. ADIM: YAZ (Transaction içinde)
        transaction.update(_firestore.collection('users').doc(userId), {
          'username': newUsername,
        });

        return true; // İşlem başarılı, isim alındı ve güncellendi.
      });
    } catch (e) {
      _logger.warn('İşlem hatası: $e');
      return false;
    }
  }

  @override
  Future<void> deleteUser(String? reason) async {
    final result = await _functions.httpsCallable('deleteAccount').call({
      'reason': reason,
    });

    if (result.data['success'] == true) {
      _logger.info(
        'User deletion function executed successfully for user',
      );
    } else {
      _logger.error(
        'User deletion function failed for user with message: ${result.data['message']}',
      );
      throw Exception('User deletion failed: ${result.data['message']}');
    }
  }

  @override
  Future<void> updateUser(
    String userID,
    Map<String, dynamic> updates,
  ) async {
    _logger.info('Updating user: $userID');
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Eğer updates içinde 'username' alanı varsa benzersizlik kontrolü yap
        if (updates.containsKey('username')) {
          final newUsername = updates['username'] as String;

          // İsmin başkası tarafından alınıp alınmadığını kontrol et
          final querySnapshot = await _firestore
              .collection('users')
              .where('username', isEqualTo: newUsername)
              .get();

          // Eğer isim varsa VE bu isim bizim şu anki userID'mize ait değilse başkası kapmış demektir
          if (querySnapshot.docs.isNotEmpty &&
              querySnapshot.docs.first.id != userID) {
            _logger.warn(
              'Username $newUsername is already taken by another user.',
            );
            throw Exception('username-already-exists');
          }
        }

        // 2. Güncelleme işlemini gerçekleştir
        final docRef = _firestore.collection('users').doc(userID);
        transaction.update(docRef, updates);

        _logger.info('User $userID successfully updated');
      });
    } catch (e) {
      _logger.warn('İşlem hatası: $e');
    }
  }

  @override
  Future<bool> isUserRegistered(String userID) async {
    final userDoc = await _firestore.collection('users').doc(userID).get();

    if (!userDoc.exists) {
      return false;
    }

    final data = userDoc.data();
    if (data == null) {
      return false;
    }

    bool registerCompleted;
    if (data['registerCompleted'] != null) {
      registerCompleted = data['registerCompleted'] as bool;
    } else {
      registerCompleted = false;
    }
    if (registerCompleted) {
      return true;
    }

    return false;
  }

  @override
  Future<bool> doesUsernameExist(String username) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    // Eğer isim varsa VE bu isim bizim şu anki userID'mize ait değilse başkası kapmış demektir
    if (querySnapshot.docs.isNotEmpty) {
      return true;
    }
    return false;
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
        .orderBy('updatedAt', descending: true)
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

    await _firestore.collection('users').doc(userID).update({
      'followerCount': FieldValue.increment(-1),
    });
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

    await _firestore.collection('users').doc(userID).update({
      'followeeCount': FieldValue.increment(1),
    });
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

    await _firestore.collection('users').doc(userID).update({
      'followeeCount': FieldValue.increment(-1),
    });
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

  @override
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
  Future<int> getFollowersCount(Identifier userID) async {
    _logger.info('Getting followers count for user: $userID');

    final snapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('followers')
        .get();

    return snapshot.size;
  }

  @override
  Future<int> getFolloweesCount(Identifier userID) async {
    _logger.info('Getting followees count for user: $userID');

    final snapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('followees')
        .get();

    return snapshot.size;
  }

  @override
  Future<void> sendFollowRequest(
    Identifier fromUserID,
    Identifier toUserID,
    bool fromNotification,
  ) async {
    _logger.info(
      'Sending follow request from user: $fromUserID to user: $toUserID',
    );

    final fromUser = await getCurrentUser(fromUserID);
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

    if (fromNotification) {
      _firestore
          .collection('users')
          .doc(fromUserID)
          .collection('followNotifications')
          .doc(toUserID)
          .set({
            'status': 'sent',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
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
    _logger.info(
      'Found posts for user: $userID, posts count: ${posts.length}',
    );
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

  //TODO: israfın amına koymak bu
  @override
  Future<int> getCompletedEventCount(Identifier userID) async {
    _logger.info('Getting completed event count for user: $userID');

    final snapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('eventLog')
        .where('status', isEqualTo: 'completed')
        .get();

    return snapshot.size;
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

  @override
  Future<bool> verifyEmail(
    String email,
    String universityName,
    String code,
  ) async {
    final response = await _functions.httpsCallable('verifyEmailCode').call({
      'universityEmail': email,
      'universityName': universityName,
      'otp': code,
    });

    return response.data['success'] as bool;
  }

  @override
  Future<void> sendVerificationEmail(
    String email,
  ) async {
    await _functions.httpsCallable('sendVerificationEmail').call({
      'email': email,
    });
  }

  @override
  Stream<List<CompactUserEntity>> watchFollowees(Identifier userID) {
    final snapshot = _firestore
        .collection('users')
        .doc(userID)
        .collection('followees')
        .snapshots();

    return snapshot.map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return CompactUserEntity.fromMap(data);
      }).toList();
    });
  }

  @override
  Stream<List<CompactUserEntity>> watchFollowers(Identifier userID) {
    final snapshot = _firestore
        .collection('users')
        .doc(userID)
        .collection('followers')
        .snapshots();

    return snapshot.map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return CompactUserEntity.fromMap(data);
      }).toList();
    });
  }

  @override
  Stream<List<CompactUserEntity>> watchBlockedUsers(Identifier userID) {
    final snapshot = _firestore
        .collection('users')
        .doc(userID)
        .collection('blockedUsers')
        .snapshots();

    return snapshot.map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        final blockedUser = CompactUserEntity.fromMap(data);
        return blockedUser;
      }).toList();
    });
  }

  @override
  Stream<List<UserEventEntity>> watchUserEventLog(Identifier userID) {
    return _firestore
        .collection('users')
        .doc(userID)
        .collection('eventLog')
        .snapshots()
        .map((querySnapshot) {
          return querySnapshot.docs.map((doc) {
            final data = doc.data();
            final model = UserEventModel.fromFirestore(data);
            return model.toEntity();
          }).toList();
        });
  }

  @override
  Stream<List<UserPostEntity>> getUserPostsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50) // <--- KRİTİK EKLEME: Sadece son 50 postu çek
        .snapshots()
        .map((querySnapshot) {
          return querySnapshot.docs.map((doc) {
            try {
              final data = doc.data();
              // fromFirestore içinde hata olursa tüm akışın çökmesini engellemek için
              // burada da try-catch blokları kullanabilirsin ama şimdilik temel hali yeterli.
              final model = UserPostModel.fromFirestore(data);
              return model.toEntity();
            } catch (e) {
              // Hatalı bir veri varsa logla ve boş döndür (veya null dönüp filter yap)
              // Hatalı postu atlamak için dummy bir veri veya null dönebilirsin.
              // Burayı basit tutmak adına rethrow yapıyorum ama prod'da dikkat et.
              rethrow;
            }
          }).toList();
        });
  }
}
