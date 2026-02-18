import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/event_card.dart';
import 'package:outnest/components/post_card.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/repositories/feed_repository.dart';

class HomeContentPage extends StatefulWidget {
  const HomeContentPage({required this.feedType, super.key});
  final FeedType feedType;

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  final ScrollController _scrollController = ScrollController();

  // Interface'imiz (Reactive yapıya uygun olan)
  final FeedRepository _feedRepository = getIt<FeedRepository>();

  // Fetch eşiği (Sayfanın sonuna ne kadar yaklaşınca yüklesin)
  final int _nextPageThreshold = AppConfig.feedFetchThreshold;

  bool _isInitialLoading = false;
  @override
  void initState() {
    super.initState();
    _feedRepository..switchFeedType(widget.feedType);
    _initFeed();
    // 2. Scroll dinleyicisi (Pagination için)
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initFeed() async {
    setState(() => _isInitialLoading = true);
    try {
      await _feedRepository.warmup();
    } catch (e, stack) {
      if (kDebugMode) debugPrint('Feed warmup hatası: $e');
      await FirebaseCrashlytics.instance.recordError(e, stack);
    } finally {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // 200px kala yükle
      _feedRepository.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        // Pull-to-refresh: Repository'deki state'i sıfırlar
        onRefresh: () async => _feedRepository.refresh(),

        // ANA AKIŞ: Repository'nin Stream'ini dinliyoruz
        child: StreamBuilder<List<FeedEntity>>(
          stream: _feedRepository.feedStream,
          builder: (context, snapshot) {
            // 1. Yükleniyor veya Veri Yok Durumu

            if (_isInitialLoading) {
              return _buildInitialLoading();
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildEmptyState();
            }

            final items = snapshot.data!;

            // 2. Listeyi Çiz
            return ListView.builder(
              controller: _scrollController,
              physics: const SlowFeedPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                if (item is PostEntity) {
                  return PostCard(post: item, user: item.creator);
                } else if (item is EventEntity) {
                  return _LiveEventItem(
                    initialEvent: item,
                    repository: _feedRepository,
                  );
                }

                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInitialLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Henüz içerik yok.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _feedRepository.refresh(),
            child: const Text('Yenile'),
          ),
        ],
      ),
    );
  }
}

class _LiveEventItem extends StatefulWidget {
  const _LiveEventItem({
    required this.initialEvent,
    required this.repository,
  });
  final EventEntity initialEvent;
  final FeedRepository repository;

  @override
  State<_LiveEventItem> createState() => _LiveEventItemState();
}

class _LiveEventItemState extends State<_LiveEventItem> {
  late final Stream<FeedEntity> _eventStream;

  @override
  void initState() {
    super.initState();
    _eventStream = widget.repository.getLiveEventStream(
      widget.initialEvent.eventID,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FeedEntity>(
      stream: _eventStream,
      initialData: widget.initialEvent,
      builder: (context, snapshot) {
        final liveData = (snapshot.data as EventEntity?) ?? widget.initialEvent;

        return EventCard(
          event: liveData,
          participants: liveData.participants,
        );
      },
    );
  }
}

// --- SCROLL  ---
class SlowFeedPhysics extends BouncingScrollPhysics {
  const SlowFeedPhysics({super.parent});

  @override
  SlowFeedPhysics applyTo(ScrollPhysics? ancestor) {
    return SlowFeedPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics metrics, double offset) {
    return offset * 0.85; // Parmakla kaydırma hızı (%15 yavaşlatıldı)
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics metrics,
    double velocity,
  ) {
    return super.createBallisticSimulation(
      metrics,
      velocity * 0.75,
    ); // Fırlatma hızı (%25 yavaşlatıldı)
  }
}
