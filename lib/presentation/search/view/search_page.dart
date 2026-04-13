import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_friend_providers.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/service_locators/search_repository_provider.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/services/file_service.dart';

class SearchPage extends HookConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final focusNode = useFocusNode();
    final scrollController = useScrollController();

    final allFollowers =
        ref.watch(currentUserFollowersProvider).asData?.value ?? [];

    final currentUser = ref.watch(currentUserEntityProvider);
    final followeeIds =
        ref
            .watch(currentUserFolloweesProvider)
            .asData
            ?.value
            .map((u) => u.userID)
            .toSet() ??
        <String>{};

    final suggestedUsers = useMemoized(
      () => (List<CompactUserEntity>.from(
        allFollowers,
      )..shuffle()).take(5).toList(),
      [allFollowers],
    );

    final users = useState<List<CompactUserEntity>>([]);
    final events = useState<List<EventEntity>>([]);
    final lastUserDoc = useRef<DocumentSnapshot?>(null);
    final lastEventDoc = useRef<DocumentSnapshot?>(null);
    final hasMoreUsers = useRef(false);
    final hasMoreEvents = useRef(false);
    final isLoading = useState(false);
    final isLoadingMore = useState(false);
    final isFocused = useState(false);
    final debounce = useRef<Timer?>(null);
    final currentQuery = useRef('');

    final repo = ref.read(searchRepositoryProvider);

    useEffect(() {
      void listener() => isFocused.value = focusNode.hasFocus;
      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    useEffect(
      () =>
          () => debounce.value?.cancel(),
      [],
    );

    Future<void> performSearch(String query) async {
      if (currentUser == null) return;
      isLoading.value = true;
      currentQuery.value = query;
      try {
        final userResult = await repo.searchUsers(
          query: query,
          followers: allFollowers,
        );
        final eventResult = await repo.searchEvents(
          query: query,
          currentUser: currentUser.value!,
        );

        users.value = userResult.users;
        events.value = eventResult.events;
        lastUserDoc.value = userResult.lastDoc;
        lastEventDoc.value = eventResult.lastDoc;
        hasMoreUsers.value = userResult.hasMore;
        hasMoreEvents.value = eventResult.hasMore;
      } catch (e) {
        debugPrint('Arama Hatası: $e');
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> loadMoreUsers() async {
      if (!hasMoreUsers.value || isLoadingMore.value) return;
      isLoadingMore.value = true;
      try {
        final excludeIds = users.value.map((u) => u.userID).toSet();
        final next = await repo.searchUsers(
          query: currentQuery.value,
          followers: allFollowers,
          startAfter: lastUserDoc.value,
          excludeIds: excludeIds,
        );
        users.value = [...users.value, ...next.users];
        lastUserDoc.value = next.lastDoc;
        hasMoreUsers.value = next.hasMore;
      } catch (e) {
        debugPrint('Sayfalama Hatası: $e');
      } finally {
        isLoadingMore.value = false;
      }
    }

    useEffect(() {
      void onScroll() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          loadMoreUsers();
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    void onSearchChanged(String query) {
      debounce.value?.cancel();
      debounce.value = Timer(const Duration(milliseconds: 300), () {
        if (query.isNotEmpty) {
          performSearch(query);
        } else {
          users.value = [];
          events.value = [];
          hasMoreUsers.value = false;
          hasMoreEvents.value = false;
        }
      });
    }

    final showSuggestions =
        isFocused.value &&
        searchController.text.isEmpty &&
        suggestedUsers.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Arama')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              focusNode: focusNode,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Kullanıcı veya buluşma ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (isLoading.value)
            const LinearProgressIndicator()
          else if (showSuggestions)
            Expanded(
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'ÖNERİLEN KULLANICILAR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...suggestedUsers.map((u) => _UserTile(user: u)),
                ],
              ),
            )
          else
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  if (users.value.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'KULLANICILAR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...users.value.map((u) => _UserTile(user: u)),
                    if (isLoadingMore.value)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                  if (events.value.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'BULUŞMALAR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...events.value.map((e) => _EventTile(event: e)),
                  ],
                  if (users.value.isEmpty &&
                      events.value.isEmpty &&
                      searchController.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('Sonuç bulunamadı.')),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final CompactUserEntity user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final raw = user.profileImageUrl;
    final hasUrl = raw.isNotEmpty && raw.startsWith('http');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        backgroundImage: hasUrl
            ? CachedNetworkImageProvider(fixEmulatorUrl(raw))
            : AssetImage(FileService.defaultProfileImageUrl()) as ImageProvider,
        onBackgroundImageError: (_, __) => debugPrint('ListTile Avatar Error'),
      ),
      title: Text(user.username),
      onTap: () {
        FocusScope.of(context).unfocus();
        context.push('/home/profile/${user.userID}');
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  final EventEntity event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.event, color: Colors.purple),
      title: Text(event.name),
      subtitle: Text(event.displayAddress),
      onTap: () {
        FocusScope.of(context).unfocus();
        context.push('/share/event/${event.eventID}');
      },
    );
  }
}
