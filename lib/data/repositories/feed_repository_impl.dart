import 'dart:math';

import 'package:bulusalim/core/constants/configs/app_config.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/event/event_model.dart';
import 'package:bulusalim/data/models/post/post_model.dart';
import 'package:bulusalim/domain/entities/user/compact_user_entity.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/domain/services/global_content_cache.dart';
import 'package:bulusalim/domain/services/in_memory_cache.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/feed/feed_entity.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
import 'package:bulusalim/domain/repositories/feed_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  final int batchSize = AppConfig.feedBatchSize;

  final FirebaseFirestore _firestore;
  final LoggingService _logger;
  final List<Identifier> _fetchedIds = [];
  Set<Identifier> _fetchedIdsSet = {};
  final int _maxFetchedIdsLength = AppConfig.feedIDListSize;

  final GlobalContentCache _cache;

  // For debugging purposes
  @override
  Future<List<FeedEntity>> fetchAllFeedItems() async {
    final batch = <FeedEntity>[];

    final snapshot = await _firestore
        .collection('feed')
        .orderBy('createdAt', descending: true)
        .get();

    final docs = snapshot.docs;

    for (final doc in docs) {
      final entity = await _entityFromDoc(doc);
      batch.add(entity);

      final id = (entity is PostEntity)
          ? entity.postID
          : (entity as EventEntity).eventID;
      _fetchedIds.add(id);
      _fetchedIdsSet.add(id);
      _cache.cacheEntity(entity);
    }

    return batch;
  }

  @override
  Future<List<FeedEntity>> fetchNextFeedBatch(
    FeedEntity? referenceFeedItem,
  ) async {
    final batch = <FeedEntity>[];

    // If first batch then ask database
    // Use cache to store fetched items

    if (referenceFeedItem == null) {
      final snapshot = await _firestore
          .collection('feed')
          .orderBy('createdAt', descending: true)
          .limit(batchSize)
          .get();

      final docs = snapshot.docs;
      for (final doc in docs) {
        final entity = await _entityFromDoc(doc);
        batch.add(entity);

        final id = (entity is PostEntity)
            ? entity.postID
            : (entity as EventEntity).eventID;
        _fetchedIds.add(id);
        _fetchedIdsSet.add(id);
        _cache.cacheEntity(entity);
      }
      return batch;
    }

    // If its not the first try to get entities from cache first
    final referenceIdx = _fetchedIdsSet.contains(referenceFeedItem.id)
        ? _fetchedIds.indexOf(referenceFeedItem.id)
        : -1;

    final missingEntityIds = <Identifier>[];

    if (referenceIdx != -1) {
      final startIndex = referenceIdx + 1;
      final endIndex = min(_fetchedIds.length, startIndex + batchSize);

      for (var i = startIndex; i < endIndex; i++) {
        final id = _fetchedIds[i];
        final cachedEntity = _cache.getEntity(id);
        // If found in cache add to batch
        if (cachedEntity != null) {
          batch.add(cachedEntity);
        } else {
          missingEntityIds.add(id);
        }
      }
    }

    // If there are missing entities fetch them from database
    if (missingEntityIds.isNotEmpty) {
      final snapshot = await _firestore
          .collection('feed')
          .where(FieldPath.documentId, whereIn: missingEntityIds)
          .orderBy('createdAt', descending: true)
          .get();

      final docs = snapshot.docs;
      for (final doc in docs) {
        final entity = await _entityFromDoc(doc);

        batch.add(entity);

        final id = (entity is PostEntity)
            ? entity.postID
            : (entity as EventEntity).eventID;
        _cache.cacheEntity(entity);
      }
    }

    if (batch.length < batchSize) {
      final lastFetchedId = batch.isNotEmpty
          ? batch.last.id
          : referenceFeedItem.id;

      final snapshot = await _firestore
          .collection('feed')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(
            await _firestore.collection('feed').doc(lastFetchedId).get(),
          )
          .limit(batchSize - batch.length)
          .get();

      final docs = snapshot.docs;
      for (final doc in docs) {
        final entity = await _entityFromDoc(doc);
        batch.add(entity);

        final id = (entity is PostEntity)
            ? entity.postID
            : (entity as EventEntity).eventID;
        _fetchedIds.add(id);
        _fetchedIdsSet.add(id);
        _cache.cacheEntity(entity);
      }
    }

    if (_fetchedIds.length > _maxFetchedIdsLength) {
      final removeCount = _fetchedIds.length - _maxFetchedIdsLength;

      _fetchedIds.removeRange(0, removeCount);

      _fetchedIdsSet = _fetchedIds.toSet();
    }
    return batch;
  }

  @override
  Future<List<FeedEntity>> fetchPreviousFeedBatch(
    FeedEntity referenceFeedItem,
  ) async {
    final batch = <FeedEntity>[];
    final referenceIdx = _fetchedIdsSet.contains(referenceFeedItem.id)
        ? _fetchedIds.indexOf(referenceFeedItem.id)
        : -1;

    final missingEntityIds = <Identifier>[];

    if (referenceIdx != -1) {
      final endIndex = referenceIdx;
      final startIndex = max(0, endIndex - batchSize);

      for (var i = startIndex; i < endIndex; i++) {
        final id = _fetchedIds[i];
        final cachedEntity = _cache.getEntity(id);
        // If found in cache add to batch
        if (cachedEntity != null) {
          batch.add(cachedEntity);
        } else {
          missingEntityIds.add(id);
        }
      }
    }
    if (missingEntityIds.isNotEmpty) {
      final snapshot = await _firestore
          .collection('feed')
          .where(FieldPath.documentId, whereIn: missingEntityIds)
          .orderBy('createdAt', descending: true)
          .get();
      final docs = snapshot.docs;
      for (final doc in docs) {
        final entity = await _entityFromDoc(doc);

        batch.add(entity);

        final id = (entity is PostEntity)
            ? entity.postID
            : (entity as EventEntity).eventID;
        _cache.cacheEntity(entity);
      }
    }

    if (batch.length < batchSize) {
      final firstFetchedId = batch.isNotEmpty
          ? batch.first.id
          : referenceFeedItem.id;

      final snapshot = await _firestore
          .collection('feed')
          .orderBy('createdAt', descending: true)
          .endBeforeDocument(
            await _firestore.collection('feed').doc(firstFetchedId).get(),
          )
          .limit(batchSize - batch.length)
          .get();

      final docs = snapshot.docs;
      final newEntities = <FeedEntity>[];
      final newIds = <Identifier>[];
      for (final doc in docs) {
        final entity = await _entityFromDoc(doc);
        newEntities.add(entity);

        final id = (entity is PostEntity)
            ? entity.postID
            : (entity as EventEntity).eventID;
        newIds.add(id);

        _cache.cacheEntity(entity);
      }
      batch.insertAll(0, newEntities);
      _fetchedIds.insertAll(0, newIds);
      _fetchedIdsSet.addAll(newIds);
    }

    if (_fetchedIds.length > _maxFetchedIdsLength) {
      final removeCount = _fetchedIds.length - _maxFetchedIdsLength;

      _fetchedIds.removeRange(
        _fetchedIds.length - removeCount,
        _fetchedIds.length,
      );

      _fetchedIdsSet = _fetchedIds.toSet();
    }
    return batch;
  }

  Future<FeedEntity> _entityFromDoc(DocumentSnapshot doc) async {
    final data = doc.data()! as Map<String, dynamic>; // Güvenli cast
    final type = data['feedType'] as String;

    FeedEntity entity;
    if (type == 'post') {
      final post = PostModel.fromFirestore(data);
      entity = post.toEntity();
    } else if (type == 'event') {
      final event = EventModel.fromFirestore(data);
      entity = await _eventRepository.enrichEventWithDetails(event.toEntity());
    } else {
      _logger.warn('Unknown feed type: $type');
      throw Exception('Unknown feed type: $type');
    }

    return entity;
  }

  @override
  Future<void> warmup() async {
    var turns = AppConfig.feedWarmupTurns;
    final batch = await fetchNextFeedBatch(null);
    _logger.info('FeedRepository warmup completed with ${batch.length} items.');

    turns = turns - 1;

    for (var i = 0; i < turns; i++) {
      if (batch.isNotEmpty) {
        final lastItem = batch.last;
        final nextBatch = await fetchNextFeedBatch(lastItem);
        _logger.info(
          'Warmup turn ${i + 1}: fetched ${nextBatch.length} items.',
        );
        if (nextBatch.isEmpty) {
          break;
        }
      } else {
        break;
      }
    }
  }
}
