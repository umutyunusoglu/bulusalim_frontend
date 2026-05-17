// presentation/home/view/home_content_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_university_verified.dart';
import 'package:outnest/application/feed_providers.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/application/providers/nav_bar_active_index_provider.dart';
import 'package:outnest/application/providers/navbar_badge_provider.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/core/utils/types/enums/screen_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';
import 'package:outnest/domain/entities/feed/idea/idea_entity.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/repositories/feed_repository.dart';
import 'package:outnest/domain/services/navbar_badge_service.dart';
import 'package:outnest/domain/services/persistance_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/profile/view/components/empty_profile_screen.dart';
import 'package:outnest/presentation/shared/event_card/view/event_card.dart';
import 'package:outnest/presentation/shared/idea_card/idea_cart.dart';
import 'package:outnest/presentation/shared/post_card/post_card.dart';

class HomeContentPage extends HookConsumerWidget {
  const HomeContentPage({required this.feedType, super.key});

  final FeedType feedType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final feedAsync = ref.watch(feedStreamProvider(feedType));
    final repo = ref.watch(feedRepositoryProvider(feedType));
    final activeNavbarIndex = ref.watch<int>(navBarActiveIndexProvider);
    final isUniversityVerified = ref.watch<bool>(
      currentUserUniversityVerifiedProvider,
    );

    // Pagination on scroll-near-end.
    useEffect(() {
      void onScroll() {
        if (!scrollController.hasClients) return;
        final pos = scrollController.position;
        if (pos.pixels >= pos.maxScrollExtent - 200) {
          repo.loadMore();
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController, repo]);

    // External "scroll to top" trigger from the nav bar.
    useEffect(() {
      if (!getIt.isRegistered<ValueNotifier<int>>(
        instanceName: 'homeScrollTrigger',
      )) {
        return null;
      }
      final trigger = getIt<ValueNotifier<int>>(
        instanceName: 'homeScrollTrigger',
      );
      void onTrigger() {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }

      trigger.addListener(onTrigger);
      return () => trigger.removeListener(onTrigger);
    }, [scrollController]);

    _useFeedBadgeSync(
      ref: ref,
      items: feedAsync.value ?? const [],
      activeTabIndex: activeNavbarIndex,
    );

    // University gate.
    if (feedType == FeedType.university && !isUniversityVerified) {
      return _UniversityGate();
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: repo.refresh,
        child: feedAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (items) {
            if (items.isEmpty) {
              return _EmptyState(onRefresh: repo.refresh);
            }
            return ListView.builder(
              controller: scrollController,
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
                }
                if (item is EventEntity) {
                  return _LiveEventItem(
                    key: ValueKey('event_${item.eventID}'),
                    initialEvent: item,
                    repository: repo,
                  );
                }
                if (item is IdeaEntity) {
                  return IdeaCard(
                    key: ValueKey('idea_${item.id}'),
                    idea: item,
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
}

void _useFeedBadgeSync({
  required WidgetRef ref,
  required List<FeedEntity> items,
  required int activeTabIndex,
}) {
  final lastNewest = useRef<int?>(null);
  final lastTab = useRef<int?>(null);
  final cachedSeen = useRef<int?>(null);

  final persistence = getIt<PersistanceService>();
  final session = getIt<SessionService>();
  final badgeService = ref.read<NavBarBadgeService>(navBarBadgeProvider);
  final userId = session.currentUser?.userID;

  // Load cached "seen" timestamp once per user.
  useEffect(() {
    if (userId == null) return null;
    () async {
      cachedSeen.value = await persistence.getInt(
        'lastFeedSeenUpdatedAt_$userId',
      );
    }();
    return null;
  }, [userId]);

  if (userId == null) return;

  if (items.isEmpty) {
    if (lastNewest.value == null && lastTab.value == activeTabIndex) return;
    lastNewest.value = null;
    lastTab.value = activeTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      badgeService.clearBadge(0);
    });
    return;
  }

  DateTime? latest;
  for (final item in items) {
    final ts = switch (item) {
      PostEntity p => p.updatedAt ?? p.createdAt,
      EventEntity e => e.updatedAt,
      IdeaEntity i => i.updatedAt ?? i.createdAt,
      _ => null,
    };
    if (ts == null) continue;
    if (latest == null || ts.isAfter(latest)) latest = ts;
  }
  if (latest == null) return;

  final newestMillis = latest.millisecondsSinceEpoch;
  if (lastNewest.value == newestMillis && lastTab.value == activeTabIndex) {
    return;
  }
  lastNewest.value = newestMillis;
  lastTab.value = activeTabIndex;

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final seenKey = 'lastFeedSeenUpdatedAt_$userId';
    final persistedSeen = cachedSeen.value ?? await persistence.getInt(seenKey);
    cachedSeen.value = persistedSeen;

    if (activeTabIndex == 0) {
      if (persistedSeen != newestMillis) {
        await persistence.saveInt(seenKey, newestMillis);
        cachedSeen.value = newestMillis;
      }
      badgeService.clearBadge(0);
    } else {
      final hasNewFeed = persistedSeen == null || newestMillis > persistedSeen;
      badgeService.setBadge(tabIndex: 0, visible: hasNewFeed);
    }
  });
}

// --- Sub-widgets ---

class _UniversityGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Henüz Üniversiteni Doğrulamadın',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const EmptyProfileScreen(
          text: 'Üniversiteni Doğrulama İçin Aşağıdaki Butona Tıklayın.',
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          const Text('Henüz içerik yok.'),
          ElevatedButton(
            onPressed: onRefresh,
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
  late final Stream<EventEntity> _eventStream;

  @override
  void initState() {
    super.initState();
    _eventStream = widget.repository.getLiveStream<EventEntity>(
      widget.initialEvent.eventID,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EventEntity>(
      stream: _eventStream,
      initialData: widget.initialEvent,
      builder: (context, snapshot) {
        final liveData = snapshot.data ?? widget.initialEvent;
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
    return super.createBallisticSimulation(metrics, velocity * 0.75);
  }
}
