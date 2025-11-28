import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/event_card.dart';
import 'package:bulusalim/components/post_card.dart';
import 'package:bulusalim/core/constants/Configs/app_config.dart';
import 'package:bulusalim/core/utils/types/enums/feed_type.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/feed/feed_entity.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
import 'package:bulusalim/domain/repositories/feed_repository.dart';
import 'package:flutter/material.dart';

class HomeContentPage extends StatefulWidget {
  const HomeContentPage({required this.feedType, super.key});
  final FeedType feedType;

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  final ScrollController _scrollController = ScrollController();

  final FeedRepository _feedRepository = getIt<FeedRepository>();

  List<FeedEntity> _feedItems = [];
  bool _isLoadingNext = false;
  bool _isInitialLoad = true;
  final LoggingService _logger = getIt<LoggingService>();

  final int _nextPageThreshold = AppConfig.feedFetchThreshold;

  @override
  void initState() {
    super.initState();
    _fetchInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitial() async {
    try {
      if (_feedItems.isEmpty) {
        setState(() => _isInitialLoad = true);
      }

      final newItems = await _feedRepository.fetchNextFeedBatch(null);

      if (mounted) {
        setState(() {
          _feedItems = newItems;
          _isInitialLoad = false;

          _isLoadingNext = false;
        });
      }
    } on Exception catch (e) {
      _logger.debug('Initial Fetch Error: $e');
      if (mounted) setState(() => _isInitialLoad = false);
    }
  }

  Future<void> _fetchNextBatch() async {
    if (_isLoadingNext || _feedItems.isEmpty) return;

    setState(() => _isLoadingNext = true);

    try {
      final lastItem = _feedItems.last;
      final newItems = await _feedRepository.fetchNextFeedBatch(lastItem);

      if (mounted) {
        if (newItems.isNotEmpty) {
          setState(() {
            _feedItems.addAll(newItems);
          });
        }
      }
    } on Exception catch (e) {
      _logger.debug('Next Batch Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingNext = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_feedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Henüz içerik yok.'),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _fetchInitial,
              icon: const Icon(Icons.refresh),
              label: const Text('Yenile'),
            ),
          ],
        ),
      );
    }

    // 3. İçerik Listesi
    return RefreshIndicator(
      onRefresh: _fetchInitial,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _feedItems.length + (_isLoadingNext ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _feedItems.length - _nextPageThreshold &&
              !_isLoadingNext) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchNextBatch();
            });
          }
          // -------------------------------

          if (index == _feedItems.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = _feedItems[index];

          if (item is PostEntity) {
            return PostCard(post: item, user: item.creator);
          } else if (item is EventEntity) {
            return EventCard(
              event: item,
              participants: item.participants,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
