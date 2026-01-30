import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/core/utils/types/enums/visibility_enum.dart';
import 'package:outnest/data/models/event/event_model.dart';
import 'package:outnest/data/models/post/post_model.dart' hide getIt;
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/repositories/feed_repository.dart';
import 'package:outnest/domain/services/global_content_cache.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:rxdart/rxdart.dart';

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl({
    required FirebaseFirestore firestore,
    required LoggingService logger,
    required GlobalContentCache cache,
    required EventRepository eventRepository,
  }) : _firestore = firestore,
       _logger = logger,
       _cache = cache,
       _eventRepository = eventRepository;

  final EventRepository _eventRepository;
  final FirebaseFirestore _firestore;
  final LoggingService _logger;
  final GlobalContentCache _cache;

  // --- STATE ---
  final BehaviorSubject<List<FeedEntity>> _feedController =
      BehaviorSubject.seeded([]);

  FeedType _currentFeedType = FeedType.all;
  bool _isLoading = false;

  // Pagination Referansları
  DocumentSnapshot? _lastPostDoc;
  DocumentSnapshot? _lastEventDoc;

  // Desen: 1 Post, 2 Event
  int _patternIndex = 0;
  final List<String> _flatPattern = [
    'P',
    'E',
    'E',
    'P',
    'E',
    'P',
    'P',
    'E',
    'E',
    'P',
    'P',
    'P',
    'E',
    'P',
    'E',
    'E',
  ];

  @override
  Stream<List<FeedEntity>> get feedStream => _feedController.stream;

  // --- PUBLIC METOTLAR ---

  @override
  Future<void> switchFeedType(FeedType type) async {
    if (_currentFeedType == type) return;
    _currentFeedType = type;
    _logger.info('🔄 Feed switched to: $type');
    await refresh();
  }

  @override
  Future<void> refresh() async {
    if (_isLoading) return;
    _resetState();
    await loadMore();
  }

  @override
  Future<void> loadMore() async {
    if (_isLoading) {
      _logger.info('⚠️ loadMore skipped: Already loading.');
      return;
    }
    _isLoading = true;

    try {
      final currentUser = getIt<SessionService>().currentUser;
      if (currentUser == null) {
        _logger.error('❌ loadMore failed: Current user is null.');
        _isLoading = false;
        return;
      }

      _logger.info(
        '🚀 loadMore started. User: ${currentUser.userID}, Uni: ${currentUser.university}, FeedType: $_currentFeedType',
      );

      // [MALİYET KORUMASI]
      const fetchLimit = AppConfig.feedBatchSize;

      // 1. Veri Çekme
      final postsFuture = _fetchTargetedPosts(fetchLimit, currentUser);
      final eventsFuture = _fetchTargetedEvents(fetchLimit, currentUser);

      final results = await Future.wait([postsFuture, eventsFuture]);
      final postDocs = results[0];
      final eventDocs = results[1];

      _logger.info(
        '📥 Firestore Raw Result: ${postDocs.length} Posts, ${eventDocs.length} Events fetched.',
      );

      if (postDocs.isEmpty && eventDocs.isEmpty) {
        _logger.info('⚠️ Both sources empty. Stopping.');
        _isLoading = false;
        return;
      }

      // 2. Cursor Güncelleme
      if (postDocs.isNotEmpty) _lastPostDoc = postDocs.last;
      if (eventDocs.isNotEmpty) _lastEventDoc = eventDocs.last;

      // 3. Filtreleme ve Birleştirme
      final newBatch = await _mergeAndFilterResults(
        postDocs,
        eventDocs,
        currentUser,
      );

      _logger.info(
        '✅ Merge complete. ${newBatch.length} items survived filtering out of ${postDocs.length + eventDocs.length}.',
      );

      // 4. Stream Güncelleme
      final currentList = _feedController.value;
      final updatedList = [...currentList, ...newBatch];
      _feedController.add(updatedList);

      // 5. Cacheleme
      for (final item in newBatch) {
        _cache.cacheEntity(item);
      }
    } catch (e) {
      _logger.error('❌ Feed Load Error: $e');
    } finally {
      _isLoading = false;
    }
  }

  // --- FETCHING LOGIC ---

  Future<List<DocumentSnapshot>> _fetchTargetedPosts(
    int limit,
    UserEntity user,
  ) async {
    try {
      if (_currentFeedType != FeedType.friendsOnly) {
        Query query = _firestore.collection('posts');

        if (_currentFeedType == FeedType.all) {
          query = query.orderBy('createdAt', descending: true);
        } else {
          // School
          query = query.orderBy('createdAt', descending: true);
        }

        if (_lastPostDoc != null) {
          query = query.startAfterDocument(_lastPostDoc!);
        }
        return (await query.limit(limit).get()).docs;
      }

      // Friends Modu
      final following = user.followeeIds;
      if (following == null || following.isEmpty) {
        _logger.info('ℹ️ Friends feed requested but followeeIds is empty.');
        return [];
      }

      final chunks = _chunkList(following, 30);
      DateTime? lastDate;
      if (_lastPostDoc != null) {
        final data = _lastPostDoc!.data()! as Map<String, dynamic>;
        lastDate = (data['createdAt'] as Timestamp).toDate();
      }

      final futures = chunks.map((chunk) {
        Query query = _firestore
            .collection('posts')
            .where('creator.userID', whereIn: chunk)
            .orderBy('createdAt', descending: true);

        if (lastDate != null) {
          query = query.startAfter([Timestamp.fromDate(lastDate)]);
        }
        return query.limit(limit).get();
      }).toList();

      final snapshots = await Future.wait(futures);
      final allDocs = snapshots.expand((s) => s.docs).toList()
        ..sort((a, b) {
          final tA =
              (a.data()! as Map<String, dynamic>)['createdAt'] as Timestamp;
          final tB =
              (b.data()! as Map<String, dynamic>)['createdAt'] as Timestamp;
          return tB.compareTo(tA);
        });

      if (allDocs.length > limit) return allDocs.sublist(0, limit);
      return allDocs;
    } catch (e) {
      _logger.error('❌ Error fetching posts: $e');
      return [];
    }
  }

  Future<List<DocumentSnapshot>> _fetchTargetedEvents(
    int limit,
    UserEntity user,
  ) async {
    try {
      if (_currentFeedType != FeedType.friendsOnly) {
        Query query = _firestore.collection('events');

        if (_currentFeedType == FeedType.all) {
          query = query.orderBy('createdAt', descending: true);
        } else {
          query = query.orderBy('createdAt', descending: true);
        }

        if (_lastEventDoc != null) {
          query = query.startAfterDocument(_lastEventDoc!);
        }
        return (await query.limit(limit).get()).docs;
      }

      // Friends Modu
      final following = user.followeeIds;
      if (following == null || following.isEmpty) return [];

      final chunks = _chunkList(following, 30);
      DateTime? lastDate;
      if (_lastEventDoc != null) {
        final data = _lastEventDoc!.data()! as Map<String, dynamic>;
        lastDate = (data['createdAt'] as Timestamp).toDate();
      }

      final futures = chunks.map((chunk) {
        Query query = _firestore
            .collection('events')
            .where('creator.userID', whereIn: chunk)
            .orderBy('createdAt', descending: true);

        if (lastDate != null) {
          query = query.startAfter([Timestamp.fromDate(lastDate)]);
        }
        return query.limit(limit).get();
      }).toList();

      final snapshots = await Future.wait(futures);
      final allDocs = snapshots.expand((s) => s.docs).toList()
        ..sort((a, b) {
          final tA =
              (a.data()! as Map<String, dynamic>)['createdAt'] as Timestamp;
          final tB =
              (b.data()! as Map<String, dynamic>)['createdAt'] as Timestamp;
          return tB.compareTo(tA);
        });

      if (allDocs.length > limit) return allDocs.sublist(0, limit);
      return allDocs;
    } catch (e) {
      _logger.error('❌ Error fetching events: $e');
      return [];
    }
  }

  // --- MERGE & FILTER ---

  Future<List<FeedEntity>> _mergeAndFilterResults(
    List<DocumentSnapshot> postDocs,
    List<DocumentSnapshot> eventDocs,
    UserEntity user,
  ) async {
    final resultBatch = <FeedEntity>[];
    final postQueue = postDocs.toList();
    final eventQueue = eventDocs.toList();

    while ((postQueue.isNotEmpty || eventQueue.isNotEmpty) &&
        resultBatch.length < AppConfig.feedBatchSize) {
      final type = _flatPattern[_patternIndex % _flatPattern.length];

      bool added = false; // Ekleme başarılı mı kontrolü için

      if (type == 'P') {
        if (postQueue.isNotEmpty) {
          // DEĞİŞİKLİK: Sonucu bir değişkene atadık
          added = await _tryAddPost(postQueue, resultBatch, user);
        } else if (eventQueue.isNotEmpty) {
          // Post bittiyse Event dene (Fallback)
          added = await _tryAddEvent(eventQueue, resultBatch, user);
        }
      } else {
        // Type E
        if (eventQueue.isNotEmpty) {
          added = await _tryAddEvent(eventQueue, resultBatch, user);
        } else if (postQueue.isNotEmpty) {
          // Event bittiyse Post dene (Fallback)
          added = await _tryAddPost(postQueue, resultBatch, user);
        }
      }

      // DEĞİŞİKLİK: Eğer listeye bir şey eklendiyse deseni ilerlet
      if (added) {
        _patternIndex++;
      }
    }
    return resultBatch;
  }

  Future<bool> _tryAddPost(
    List<DocumentSnapshot> queue,
    List<FeedEntity> result,
    UserEntity user,
  ) async {
    while (queue.isNotEmpty) {
      final doc = queue.removeAt(0);
      final data = doc.data()! as Map<String, dynamic>;
      final model = PostModel.fromFirestore(data);

      // --- LOGGING ---
      final creatorUni = model.creator.university;
      final userUni = user.university;
      // ---------------

      // Okul Modu Kontrolü
      if (_currentFeedType == FeedType.university) {
        if (creatorUni != userUni) {
          _logger.info(
            '🚫 Post Filtered (Uni Mismatch): PostCreatorUni($creatorUni) != UserUni($userUni)',
          );
          continue;
        }
      }

      result.add(model.toEntity());
      return true;
    }
    return false;
  }

  Future<bool> _tryAddEvent(
    List<DocumentSnapshot> queue,
    List<FeedEntity> result,
    UserEntity user,
  ) async {
    while (queue.isNotEmpty) {
      final doc = queue.removeAt(0);
      final data = doc.data()! as Map<String, dynamic>;
      final model = EventModel.fromFirestore(data);
      final entity = model.toEntity();

      // 1. Okul Feed Kontrolü
      if (_currentFeedType == FeedType.university) {
        if (entity.creator.university != user.university) {
          _logger.info(
            '🚫 Event Filtered (Uni Mismatch): EventCreatorUni(${entity.creator.university}) != UserUni(${user.university})',
          );
          continue;
        }
      }

      // 2. Visibility Kontrolü
      if (_canUserSeeEvent(entity, user)) {
        final enriched = await _eventRepository.enrichEventWithDetails(entity);
        result.add(enriched);
        return true;
      } else {
        _logger.info(
          '🚫 Event Filtered (Visibility): User cannot see Event ${entity.eventID}. Visibility: ${entity.visibility}',
        );
      }
    }
    return false;
  }

  bool _canUserSeeEvent(EventEntity event, UserEntity currentUser) {
    if (event.creator.userID == currentUser.userID) return true;

    if (event.visibility == null) return true;

    if (_currentFeedType == FeedType.all &&
        event.visibility == VisibilityEnum.university) {
      if (event.creator.university != currentUser.university) {
        return false;
      }
    }

    switch (event.visibility) {
      case VisibilityEnum.everyone:
        return true;
      case VisibilityEnum.university:
        return event.creator.university == currentUser.university;
      case VisibilityEnum.onlyFriends:
        if (currentUser.followeeIds == null) return false;
        return currentUser.followeeIds!.contains(event.creator.userID);
      case VisibilityEnum.custom:
        return true;
      default:
        return true;
    }
  }

  // --- LIVE UPDATES & UTILS ---
  @override
  Stream<FeedEntity> getLiveEventStream(String eventId) {
    return _firestore.collection('events').doc(eventId).snapshots().asyncMap((
      doc,
    ) async {
      if (!doc.exists) {
        final cached = _cache.getEntity(eventId);
        if (cached != null) return cached;
        throw Exception('Event Deleted');
      }
      final model = EventModel.fromFirestore(doc.data()!);
      return _eventRepository.enrichEventWithDetails(model.toEntity());
    });
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  void _resetState() {
    _lastPostDoc = null;
    _lastEventDoc = null;
    _patternIndex = 0;
    _feedController.add([]);
    _isLoading = false;
  }

  @override
  Future<List<FeedEntity>> fetchAllFeedItems() async => [];
  @override
  Future<List<FeedEntity>> fetchNextFeedBatch(FeedEntity? item) async => [];
  @override
  Future<List<FeedEntity>> fetchPreviousFeedBatch(FeedEntity item) async => [];
  @override
  Future<void> warmup() async {}

  @override
  void dispose() {
    _feedController.close();
  }
}
