// data/repositories/feed_repository_impl.dart

import 'dart:async';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';
import 'package:outnest/domain/entities/feed/sources/feed_source.dart';
import 'package:outnest/domain/repositories/feed_repository.dart';
import 'package:outnest/domain/services/global_content_cache.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:rxdart/rxdart.dart';

/// Orchestrates a set of [FeedSource]s into a single chronological
/// feed stream.
///
/// Responsibilities are deliberately narrow:
///   - building the [FeedFetchContext] from the current session,
///   - asking every source for a batch in parallel,
///   - merging results by [FeedEntity.sortDate],
///   - exposing the result as a stream and caching items.
///
/// Source-specific concerns (queries, cursors, filters, enrichment,
/// live updates) live inside the sources themselves. Adding a new
/// content type is a matter of implementing [FeedSource] and
/// registering it — no changes here.
class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl({
    required List<FeedSource> sources,
    required LoggingService logger,
    required GlobalContentCache cache,
    required FeedType feedType,
  }) : _sources = sources,
       _logger = logger,
       _cache = cache,
       _feedType = feedType;

  final List<FeedSource> _sources;
  final LoggingService _logger;
  final GlobalContentCache _cache;

  final BehaviorSubject<List<FeedEntity>> _feedController = BehaviorSubject();
  final FeedType _feedType;
  bool _isLoading = false;

  @override
  Stream<List<FeedEntity>> get feedStream => _feedController.stream;

  @override
  Future<void> refresh() async {
    if (_isLoading) return;
    _resetSources();
    await loadMore(isRefresh: true);
  }

  @override
  Future<void> loadMore({bool isRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final context = _buildContext();
      if (context == null) {
        _logger.error('❌ loadMore failed: Current user is null.');
        return;
      }

      // Fetch every source in parallel; each returns already
      // filtered & enriched entities.
      final batches = await Future.wait(
        _sources.map(
          (s) => s.fetch(context: context, limit: AppConfig.feedBatchSize),
        ),
      );

      final newBatch = batches.expand((b) => b).toList()
        ..sort((a, b) => b.sortDate.compareTo(a.sortDate));

      if (newBatch.isEmpty) {
        _logger.info('⚠️ All sources empty. No more data.');
        return;
      }

      _feedController.add(
        isRefresh ? newBatch : [..._feedController.value, ...newBatch],
      );

      newBatch.forEach(_cache.cacheEntity);
    } catch (e) {
      _logger.error('❌ Feed Load Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  @override
  Stream<T> getLiveStream<T extends FeedEntity>(String id) {
    final source = _sources.whereType<LiveFeedSource>().firstWhere(
      (s) => s.entityType == T,
      orElse: () => throw StateError(
        'No LiveFeedSource registered for type $T',
      ),
    );
    return source.liveStream(id) as Stream<T>;
  }

  @override
  Future<void> warmup() async {
    _logger.info('🚀 Feed warmup: Starting prefetch engine...');

    final sessionService = getIt<SessionService>();
    var user = sessionService.currentState.user;

    if (user == null) {
      await sessionService.refreshSession();
      user = sessionService.currentState.user;
    }

    // Wait reactively for the session user instead of polling.
    if (user == null) {
      final completer = Completer<void>();
      void onSessionChanged() {
        if (sessionService.currentState.user != null &&
            !completer.isCompleted) {
          completer.complete();
        }
      }

      sessionService.stateListenable.addListener(onSessionChanged);
      try {
        onSessionChanged();
        await completer.future.timeout(const Duration(seconds: 20));
      } on TimeoutException {
        // Fall through to the warn + skip branch below.
      } finally {
        sessionService.stateListenable.removeListener(onSessionChanged);
      }

      user = sessionService.currentState.user;
    }

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

  // --- Internals ---

  FeedFetchContext? _buildContext() {
    final session = getIt<SessionService>().currentState;
    final user = session.user;
    if (user == null) return null;

    return FeedFetchContext(
      user: user,
      followeeIds: session.followees.map((e) => e.userID).toList(),
      blockedIds: session.blockedUsers.map((e) => e.userID).toSet(),
      feedType: _feedType,
    );
  }

  void _resetSources() {
    for (final source in _sources) {
      source.reset();
    }
  }

  @override
  void removeItem(String id) {
    if (!_feedController.hasValue) return;
    final next = _feedController.value.where((e) => e.id != id).toList();
    _feedController.add(next);
  }
}
