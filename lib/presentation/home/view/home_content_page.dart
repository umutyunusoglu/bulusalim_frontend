import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_university_verified.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/application/providers/nav_bar_active_index_provider.dart';
import 'package:outnest/application/providers/navbar_badge_provider.dart';
import 'package:outnest/presentation/profile/view/components/empty_profile_screen.dart';
import 'package:outnest/presentation/shared/event_card/view/event_card.dart';
import 'package:outnest/presentation/shared/post_card/post_card.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/core/utils/types/enums/screen_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/repositories/feed_repository.dart';
import 'package:outnest/domain/services/persistance_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/services/navbar_badge_service.dart';
import 'package:outnest/presentation/profile/view/components/empty_profile_screen.dart';
import 'package:outnest/presentation/shared/event_card/view/event_card.dart';
import 'package:outnest/presentation/shared/post_card/post_card.dart';

// Provider import
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';

class HomeContentPage extends ConsumerStatefulWidget {
  const HomeContentPage({required this.feedType, super.key});
  final FeedType feedType;

  @override
  ConsumerState<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends ConsumerState<HomeContentPage> {
  final ScrollController _scrollController = ScrollController();
  final FeedRepository _feedRepository = getIt<FeedRepository>();
  final PersistanceService _persistenceService = getIt<PersistanceService>();
  final SessionService _sessionService = getIt<SessionService>();

  bool _isInitialLoading = false;
  int? _lastProcessedNewestFeedTimestamp;
  int? _lastProcessedActiveTabIndex;
  int? _cachedFeedSeenTimestamp;

  @override
  void initState() {
    super.initState();
    _feedRepository.switchFeedType(widget.feedType);
    _initFeed();
    _scrollController.addListener(_onScroll);
    _loadCachedFeedSeenTimestamp();

    if (getIt.isRegistered<ValueNotifier<int>>(
      instanceName: 'homeScrollTrigger',
    )) {
      getIt<ValueNotifier<int>>(
        instanceName: 'homeScrollTrigger',
      ).addListener(_scrollToTopIfActive);
    }
  }

  void _scrollToTopIfActive() {
    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
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

  Future<void> _loadCachedFeedSeenTimestamp() async {
    final userId = _sessionService.currentUser?.userID;
    if (userId == null) return;

    _cachedFeedSeenTimestamp = await _persistenceService.getInt(
      _feedSeenKey(userId),
    );

    if (mounted) {
      setState(() {});
    }
  }

  String _feedSeenKey(String userId) {
    return 'lastFeedSeenUpdatedAt_$userId';
  }

  DateTime? _extractFeedTimestamp(FeedEntity item) {
    if (item is PostEntity) {
      return item.updatedAt ?? item.createdAt;
    }

    if (item is EventEntity) {
      return item.updatedAt;
    }

    return null;
  }

  DateTime? _latestFeedTimestamp(List<FeedEntity> items) {
    DateTime? latest;
    for (final item in items) {
      final timestamp = _extractFeedTimestamp(item);
      if (timestamp == null) continue;
      if (latest == null || timestamp.isAfter(latest)) {
        latest = timestamp;
      }
    }
    return latest;
  }

  void _syncFeedBadgeState(List<FeedEntity> items, int activeTabIndex) {
    final badgeService = ref.read<NavBarBadgeService>(navBarBadgeProvider);
    final userId = _sessionService.currentUser?.userID;
    if (userId == null) return;

    if (items.isEmpty) {
      if (_lastProcessedNewestFeedTimestamp == null &&
          _lastProcessedActiveTabIndex == activeTabIndex) {
        return;
      }

      _lastProcessedNewestFeedTimestamp = null;
      _lastProcessedActiveTabIndex = activeTabIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        badgeService.clearBadge(0);
      });
      return;
    }

    final newestTimestamp = _latestFeedTimestamp(items);
    if (newestTimestamp == null) return;

    final newestMillis = newestTimestamp.millisecondsSinceEpoch;
    if (_lastProcessedNewestFeedTimestamp == newestMillis &&
        _lastProcessedActiveTabIndex == activeTabIndex) {
      return;
    }

    _lastProcessedNewestFeedTimestamp = newestMillis;
    _lastProcessedActiveTabIndex = activeTabIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final seenKey = _feedSeenKey(userId);
      final persistedSeen =
          _cachedFeedSeenTimestamp ?? await _persistenceService.getInt(seenKey);
      _cachedFeedSeenTimestamp = persistedSeen;

      if (activeTabIndex == 0) {
        if (persistedSeen != newestMillis) {
          await _persistenceService.saveInt(seenKey, newestMillis);
          _cachedFeedSeenTimestamp = newestMillis;
        }
        badgeService.clearBadge(0);
      } else {
        final hasNewFeed = persistedSeen == null || newestMillis > persistedSeen;
        badgeService.setBadge(tabIndex: 0, visible: hasNewFeed);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _feedRepository.loadMore();
    }
  }

  @override
  void dispose() {
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
    // Provider ile üniversite doğrulama kontrolü
    final isUniversityVerified = ref.watch<bool>(
      currentUserUniversityVerifiedProvider,
    );
    final activeNavbarIndex = ref.watch<int>(navBarActiveIndexProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _feedRepository.refresh(),
        child: StreamBuilder<List<FeedEntity>>(
          stream: _feedRepository.feedStream,
          builder: (context, snapshot) {
            if (_isInitialLoading ||
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Provider'dan gelen değer ile kontrol
            if (widget.feedType == FeedType.university &&
                !isUniversityVerified) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Henüz Üniversiteni Doğrulamadın',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const EmptyProfileScreen(
                    text:
                        'Üniversiteni Doğrulama İçin Aşağıdaki Butona Tıklayın.',
                    icon: Icon(Icons.school),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/settings/edit-account'),
                    child: const Text('Üniversiteni Doğrula'),
                  ),
                ],
              );
            }

            final items = snapshot.data;
            if (items == null || items.isEmpty) {
              _syncFeedBadgeState(const [], activeNavbarIndex);
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildEmptyState();
            }

            _syncFeedBadgeState(items, activeNavbarIndex);

            return ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: SlowFeedPhysics(),
              ),
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
          const SizedBox(height: 16),
          const Text('Henüz içerik yok.'),
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
