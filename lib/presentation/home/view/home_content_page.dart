import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/presentation/shared/event_card/event_card.dart';
import 'package:outnest/presentation/shared/post_card/post_card.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/core/utils/types/enums/screen_enum.dart';
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

  // Interface'imiz
  final FeedRepository _feedRepository = getIt<FeedRepository>();

  // Fetch eşiği

  bool _isInitialLoading = false;

  @override
  void initState() {
    super.initState();
    _feedRepository.switchFeedType(widget.feedType);

    _initFeed();

    // 2. Scroll dinleyicisi (Pagination için)
    _scrollController.addListener(_onScroll);

    // Home butonuna basıldığında tetiklenen sinyali dinliyoruz
    if (getIt.isRegistered<ValueNotifier<int>>(
      instanceName: 'homeScrollTrigger',
    )) {
      getIt<ValueNotifier<int>>(
        instanceName: 'homeScrollTrigger',
      ).addListener(_scrollToTopIfActive);
    }
  }

  // YUKARI SARMA
  void _scrollToTopIfActive() {
    // 1. Sayfa o an ekranda mı (mounted)?
    // 2. Controller listeye bağlı mı (hasClients)?
    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        0, // En başa git
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
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
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      // 200px kala yükle
      _feedRepository.loadMore();
    }
  }

  @override
  void dispose() {
    // Sayfadan çıkarken dinlemeyi bırakıyoruz (Memory leak olmasın)
    if (getIt.isRegistered<ValueNotifier<int>>(
      instanceName: 'homeScrollTrigger',
    )) {
      getIt<ValueNotifier<int>>(
        instanceName: 'homeScrollTrigger',
      ).removeListener(_scrollToTopIfActive);
    }

    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _feedRepository.refresh(),
        child: StreamBuilder<List<FeedEntity>>(
          stream: _feedRepository.feedStream,
          builder: (context, snapshot) {
            // 1. Manuel kontrol veya Stream'in ilk bekleme anı
            if (_isInitialLoading ||
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // 3. Veri Yok veya Boş Liste Durumu
            final items = snapshot.data;
            if (items == null || items.isEmpty) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Sadece gerçekten "bekleme" bitmiş ve hala veri yoksa empty state göster
              return _buildEmptyState();
            }
            // 4. Veri Geldiğinde Liste Görünümü
            return ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: SlowFeedPhysics(),
              ), // RefreshIndicator için AlwaysScrollable önemli
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                if (item is PostEntity) {
                  return PostCard(
                    key: ValueKey('post_${item.postID}'),
                    post: item,
                    user: item.creator,
                  );
                } else if (item is EventEntity) {
                  return _LiveEventItem(
                    key: ValueKey('event_${item.eventID}'),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Henüz içerik yok.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _feedRepository.refresh(),
            //loading
            child: const Text(''),
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
    super.key,
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
          screen: ScreenEnum.home,
        );
      },
    );
  }
}

class SlowFeedPhysics extends BouncingScrollPhysics {
  const SlowFeedPhysics({super.parent});

  @override
  SlowFeedPhysics applyTo(ScrollPhysics? ancestor) {
    return SlowFeedPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics metrics, double offset) {
    return offset * 0.85;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics metrics,
    double velocity,
  ) {
    return super.createBallisticSimulation(
      metrics,
      velocity * 0.75,
    );
  }
}
