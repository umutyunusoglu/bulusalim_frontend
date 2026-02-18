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
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/repositories/feed_repository.dart';
import 'package:outnest/domain/services/global_content_cache.dart';
import 'package:outnest/domain/services/remote_config_service.dart';
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

  DocumentSnapshot? _lastPostDoc;
  DocumentSnapshot? _lastEventDoc;
  bool _isPatternEnabled = AppConfig.isFeedPatternEnabled;
  // Karıştırma paterni (P: Post, E: Event)
  int _patternIndex = 0;
  static const List<String> _flatPattern = [
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

  // --- PUBLIC METHODS ---

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
    if (_isLoading) return;
    _isLoading = true;

    try {
      final sessionService = getIt<SessionService>();
      final currentUser = sessionService.currentState.user;
      final followeeIds = sessionService.currentState.followees
          .map((e) => e.userID)
          .toList();
      final blockedIds = sessionService.currentState.blockedUsers
          .map((e) => e.userID)
          .toSet();
      if (currentUser == null) {
        _logger.error('❌ loadMore failed: Current user is null.');
        return;
      }

      const fetchLimit = AppConfig.feedBatchSize;

      // 1. Verileri Çek
      final results = await Future.wait([
        _fetchPosts(fetchLimit, currentUser, followeeIds),
        _fetchEvents(fetchLimit, currentUser, followeeIds),
      ]);

      final postDocs = results[0];
      final eventDocs = results[1];

      // 2. Pagination State Güncelle
      if (postDocs.isNotEmpty) _lastPostDoc = postDocs.last;
      if (eventDocs.isNotEmpty) _lastEventDoc = eventDocs.last;

      if (postDocs.isEmpty && eventDocs.isEmpty) {
        _logger.info('⚠️ Both sources empty. No more data.');
        return;
      }

      // 3. Verileri Birleştir ve İşle
      final newBatch = await _mergeAndProcessResults(
        postDocs,
        eventDocs,
        currentUser,
        followeeIds,
        blockedIds,
      );

      // 4. Listeye Ekle ve Cache'le
      final currentList = _feedController.value;
      _feedController.add([...currentList, ...newBatch]);

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

  /// Firestore Query mantığını FeedType'a göre oluşturur.
  /// Not: University filtresini burada yaparak performansı artırıyoruz.
  Query _buildBaseQuery(CollectionReference collection, UserEntity user) {
    var query = collection.orderBy('createdAt', descending: true);

    if (_currentFeedType == FeedType.university) {
      // Buradaki null kontrolünü kaldırdık, çünkü yukarıda (fetch metodunda) engelleyeceğiz.
      // Artık buraya geldiğinde user.university'nin dolu olduğundan eminiz.
      query = query.where('creator.university', isEqualTo: user.university);
    }

    return query;
  }

  Future<List<DocumentSnapshot>> _fetchPosts(
    int limit,
    UserEntity user,
    List<String> followeeIds,
  ) async {
    // DÜZELTME: Eğer FeedType University ise VE kullanıcının üniversitesi yoksa BOŞ LİSTE dön.
    if (_currentFeedType == FeedType.university && user.university == null) {
      _logger.info(
        '⚠️ University Feed requested but user has no university. Returning empty.',
      );
      return [];
    }

    final collection = _firestore.collection('posts');

    if (_currentFeedType == FeedType.friendsOnly) {
      return _fetchFriendsContent(collection, followeeIds, limit, _lastPostDoc);
    }

    var query = _buildBaseQuery(collection, user);
    if (_lastPostDoc != null) {
      query = query.startAfterDocument(_lastPostDoc!);
    }
    return (await query.limit(limit).get()).docs;
  }

  Future<List<DocumentSnapshot>> _fetchEvents(
    int limit,
    UserEntity user,
    List<String> followeeIds,
  ) async {
    // DÜZELTME: Aynı kontrolü burada da yapıyoruz.
    if (_currentFeedType == FeedType.university && user.university == null) {
      return [];
    }

    final collection = _firestore.collection('events');

    if (_currentFeedType == FeedType.friendsOnly) {
      return _fetchFriendsContent(
        collection,
        followeeIds,
        limit,
        _lastEventDoc,
      );
    }

    var query = _buildBaseQuery(collection, user);
    if (_lastEventDoc != null) {
      query = query.startAfterDocument(_lastEventDoc!);
    }
    return (await query.limit(limit).get()).docs;
  }

  /// Arkadaş içeriklerini çekmek için yardımcı metod (DRY prensibi)
  Future<List<DocumentSnapshot>> _fetchFriendsContent(
    CollectionReference collection,
    List<String> followeeIds,
    int limit,
    DocumentSnapshot? lastDoc,
  ) async {
    if (followeeIds.isEmpty) return [];

    final chunks = _chunkList(followeeIds, 30); // Firestore `whereIn` limiti
    DateTime? lastDate;

    if (lastDoc != null) {
      final data = lastDoc.data()! as Map<String, dynamic>;
      lastDate = (data['createdAt'] as Timestamp).toDate();
    }

    final futures = chunks.map((chunk) {
      var query = collection
          .where('creator.userID', whereIn: chunk)
          .orderBy('createdAt', descending: true);

      if (lastDate != null) {
        query = query.startAfter([Timestamp.fromDate(lastDate)]);
      }
      return query.limit(limit).get();
    }).toList();

    final snapshots = await Future.wait(futures);

    // Tüm chunk'ları birleştir ve yeniden sırala
    final allDocs = snapshots.expand((s) => s.docs).toList()
      ..sort((a, b) {
        final tA =
            (a.data()! as Map<String, dynamic>)['createdAt'] as Timestamp;
        final tB =
            (b.data()! as Map<String, dynamic>)['createdAt'] as Timestamp;
        return tB.compareTo(tA);
      });

    return allDocs.length > limit ? allDocs.sublist(0, limit) : allDocs;
  }

  // --- MERGE & PROCESS ---
  Future<List<FeedEntity>> _mergeAndProcessResults(
    List<DocumentSnapshot> postDocs,
    List<DocumentSnapshot> eventDocs,
    UserEntity user,
    List<String> followeeIds,
    Set<String> blockedIds,
  ) async {
    final resultBatch = <FeedEntity>[];
    final postQueue = List<DocumentSnapshot>.from(postDocs);
    final eventQueue = List<DocumentSnapshot>.from(eventDocs);

    while ((postQueue.isNotEmpty || eventQueue.isNotEmpty) &&
        resultBatch.length < AppConfig.feedBatchSize) {
      bool added = false;

      // --- MOD KONTROLÜ ---
      if (_isPatternEnabled) {
        // A. PATTERN MANTIĞI (Mevcut kodun)
        final type = _flatPattern[_patternIndex % _flatPattern.length];

        if (type == 'P') {
          if (postQueue.isNotEmpty) {
            added = await _tryAddPost(postQueue, resultBatch, blockedIds);
          } else if (eventQueue.isNotEmpty) {
            added = await _tryAddEvent(
              eventQueue,
              resultBatch,
              user,
              followeeIds,
              blockedIds,
            );
          }
        } else {
          // Type == 'E'
          if (eventQueue.isNotEmpty) {
            added = await _tryAddEvent(
              eventQueue,
              resultBatch,
              user,
              followeeIds,
              blockedIds,
            );
          } else if (postQueue.isNotEmpty) {
            added = await _tryAddPost(postQueue, resultBatch, blockedIds);
          }
        }

        // Sadece pattern modunda index artmalı
        if (added) _patternIndex++;
      } else {
        // B. ZAMAN SIRALI MANTIK (Kronolojik)
        // İki listenin en başındaki elemanların tarihlerini karşılaştır.

        DateTime? postTime;
        DateTime? eventTime;

        if (postQueue.isNotEmpty) {
          final data = postQueue.first.data() as Map<String, dynamic>;
          postTime = (data['createdAt'] as Timestamp).toDate();
        }

        if (eventQueue.isNotEmpty) {
          final data = eventQueue.first.data() as Map<String, dynamic>;
          eventTime = (data['createdAt'] as Timestamp).toDate();
        }

        // Karşılaştırma: Hangisi daha yeniyse (büyükse) onu işlemeye çalış
        if (postTime != null && eventTime != null) {
          if (postTime.isAfter(eventTime)) {
            added = await _tryAddPost(postQueue, resultBatch, blockedIds);
          } else {
            added = await _tryAddEvent(
              eventQueue,
              resultBatch,
              user,
              followeeIds,
              blockedIds,
            );
          }
        } else if (postTime != null) {
          // Sadece post kaldıysa
          added = await _tryAddPost(postQueue, resultBatch, blockedIds);
        } else if (eventTime != null) {
          // Sadece event kaldıysa
          added = await _tryAddEvent(
            eventQueue,
            resultBatch,
            user,
            followeeIds,
            blockedIds,
          );
        }
      }
    }
    return resultBatch;
  }

  Future<bool> _tryAddPost(
    List<DocumentSnapshot> queue,
    List<FeedEntity> result,
    Set<String> blockedIds, // Eklendi
  ) async {
    if (queue.isEmpty) return false;

    final doc = queue.removeAt(0);
    final data = doc.data()! as Map<String, dynamic>;

    // FİLTRE: Eğer creator engellenenler arasındaysa ekleme
    final creatorId = (data['creator'] as Map<String, dynamic>)['userID'];
    if (blockedIds.contains(creatorId)) {
      _logger.info('🚫 Filtering out post from blocked user: $creatorId');
      return false;
    }

    final model = PostModel.fromFirestore(data);
    result.add(model.toEntity());
    return true;
  }

  Future<bool> _tryAddEvent(
    List<DocumentSnapshot> queue,
    List<FeedEntity> result,
    UserEntity user,
    List<String> followeeIds,
    Set<String> blockedIds, // Eklendi
  ) async {
    if (queue.isEmpty) return false;

    final doc = queue.removeAt(0);
    final data = doc.data()! as Map<String, dynamic>;

    // FİLTRE: Eğer creator engellenenler arasındaysa ekleme
    final creatorId = (data['creator'] as Map<String, dynamic>)['userID'];
    if (blockedIds.contains(creatorId)) {
      _logger.info('🚫 Filtering out event from blocked user: $creatorId');
      return false;
    }

    final model = EventModel.fromFirestore(data);
    final entity = model.toEntity();

    if (_canUserSeeEvent(entity, user, followeeIds)) {
      final enriched = await _eventRepository.enrichEventWithDetails(entity);
      result.add(enriched);
      return true;
    }

    return false;
  }

  bool _canUserSeeEvent(
    EventEntity event,
    UserEntity currentUser,
    List<String> followeeIds,
  ) {
    // Kendi etkinliği ise her zaman gör
    if (event.creator.userID == currentUser.userID) return true;

    // Üniversite feed'inde dışarıdan gelen ama 'university' visibility olan event kontrolü
    if (_currentFeedType == FeedType.all &&
        event.visibility == VisibilityEnum.university) {
      if (event.creator.university != currentUser.university) return false;
    }

    switch (event.visibility) {
      case VisibilityEnum.everyone:
        return true;
      case VisibilityEnum.university:
        if (currentUser.university == null) return false;

        return event.creator.university == currentUser.university;
      case VisibilityEnum.onlyFriends:
        return followeeIds.contains(event.creator.userID);
      case VisibilityEnum.custom:
        return true; // Özel mantık eklenebilir
      default:
        return true;
    }
  }

  // --- UTILS & HELPERS ---

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    return List.generate(
      (list.length / chunkSize).ceil(),
      (i) => list.sublist(
        i * chunkSize,
        (i + 1) * chunkSize > list.length ? list.length : (i + 1) * chunkSize,
      ),
    );
  }

  void _resetState() {
    _lastPostDoc = null;
    _lastEventDoc = null;
    _patternIndex = 0;
    _feedController.add([]);
    _isLoading = false;
  }

  // --- OTHER OVERRIDES ---
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

  @override
  Future<List<FeedEntity>> fetchAllFeedItems() async => [];
  @override
  Future<List<FeedEntity>> fetchNextFeedBatch(FeedEntity? item) async => [];
  @override
  Future<List<FeedEntity>> fetchPreviousFeedBatch(FeedEntity item) async => [];
  @override
  Future<void> warmup() async {
    _logger.info('🚀 Feed warmup: Starting prefetch engine...');

    final sessionService = getIt<SessionService>();
    var attempts = 0;
    const maxAttempts = 60;
    while (sessionService.currentState.user == null && attempts < maxAttempts) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    // 2. Kullanıcı bulunduysa veya limit dolduysa durumu kontrol et
    final user = sessionService.currentState.user;

    if (user != null) {
      _logger.info('✅ Warmup: User found. Triggering initial refresh...');

      await refresh();
    } else {
      _logger.warn(
        '⚠️ Warmup: Timeout waiting for user. Initial refresh skipped.',
      );
    }
  }

  @override
  void dispose() {
    _feedController.close();
  }
}
