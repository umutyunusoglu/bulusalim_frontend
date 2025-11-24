import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/event_card.dart';
import 'package:bulusalim/components/post_card.dart';
import 'package:bulusalim/core/constants/Configs/app_config.dart';
import 'package:bulusalim/core/enums/feed_type.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/feed/feed_entity.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/domain/repositories/feed_repository.dart';
import 'package:bulusalim/domain/repositories/post_repository.dart';
import 'package:bulusalim/domain/repositories/user_repository.dart';
import 'package:flutter/material.dart';

class HomeContentPage extends StatefulWidget {
  const HomeContentPage({required this.feedType, super.key});
  final FeedType feedType;

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  final ScrollController _scrollController = ScrollController();

  List<FeedEntity> _feedItems = [];
  bool _isLoadingNext = false;
  bool _isLoadingPrev = false;
  bool _isInitialLoad = true;

  final double _scrollThreshold = 800.0; // Pixel buffer for triggering fetch

  final _feedRepository = getIt<FeedRepository>();

  @override
  void initState() {
    super.initState();
    // 1. Setup Listener
    _scrollController.addListener(_onScroll);
    // 2. Initial Fetch
    _fetchInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // 1. Trigger Fetch Next (Bottom)
    // If we are within the threshold of the bottom and not already loading
    if (currentScroll >= (maxScroll - _scrollThreshold) && !_isLoadingNext) {
      _fetchNextBatch();
    }

    // 2. Trigger Fetch Previous (Top)
    // If we are near the top (scrolling up) and not already loading
    if (currentScroll <= _scrollThreshold && !_isLoadingPrev) {
      // Ensure we aren't at the absolute top (0) unless you want pull-to-refresh behavior
      // This logic depends on if 'previous' implies history or updates.
      _fetchPreviousBatch();
    }
  }

  Future<void> _fetchInitial() async {
    try {
      final newItems = await _feedRepository.fetchNextFeedBatch(
        null,
      );

      if (mounted) {
        setState(() {
          _feedItems = newItems;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      // Handle Error
    }
  }

  Future<void> _fetchNextBatch() async {
    setState(() => _isLoadingNext = true);

    try {
      final lastPost = _feedItems.last;
      final newItems = await _feedRepository.fetchNextFeedBatch(
        lastPost,
      );

      if (mounted && newItems.isNotEmpty) {
        setState(() {
          _feedItems.addAll(newItems);
        });
      }
    } catch (e) {
      print("Error fetching next: $e");
    } finally {
      if (mounted) setState(() => _isLoadingNext = false);
    }
  }

  Future<void> _fetchPreviousBatch() async {
    // Prevent spamming the top trigger
    if (_feedItems.isEmpty) return;

    setState(() => _isLoadingPrev = true);

    try {
      final firstPost = _feedItems.first;
      // Assuming you have a similar method for 'previous'
      // If your API is purely time-based, this might fetch items NEWER than 'firstPost'
      final newItems = await _feedRepository.fetchPreviousFeedBatch(
        firstPost,
      );

      if (mounted && newItems.isNotEmpty) {
        // --- CRITICAL UI FIX ---
        // When you insert at the top, the scroll view will visually "jump" because
        // index 0 changes. We must save the previous scroll extent to fix this.
        // (Note: For perfect bidirectional scrolling, use a 'center' key or advanced physics,
        // but this manual adjustment works for basic cases).

        double previousHeight = _scrollController.position.maxScrollExtent;

        setState(() {
          _feedItems.insertAll(0, newItems);
        });

        // Post-frame: adjust scroll so user doesn't lose position
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final newHeight = _scrollController.position.maxScrollExtent;
          final double heightDifference = newHeight - previousHeight;
          _scrollController.jumpTo(_scrollController.offset + heightDifference);
        });
      }
    } catch (e) {
      print("Error fetching previous: $e");
    } finally {
      if (mounted) setState(() => _isLoadingPrev = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Loading State
    if (_isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Empty State (Fix for "seeing nothing" if API returns [])
    if (_feedItems.isEmpty) {
      return const Center(
        child: Text("Henüz içerik yok."), // "No content yet"
      );
    }
    const itemThreshold = AppConfig.feedFetchThreshold;

    return ListView.builder(
      controller: _scrollController,
      itemCount: _feedItems.length + (_isLoadingNext ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _feedItems.length - itemThreshold &&
            !_isLoadingNext &&
            !_isInitialLoad) {
          // Build işlemi sırasında setState çağırmamak için
          // işlemi frame sonuna erteliyoruz (Microtask)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchNextBatch();
          });
        }

        // --- PREVIOUS (YUKARI) TETİKLEME ---
        // Eğer listenin başındaysak (örn: ilk 3 elemandan biri)
        // Ve yukarı scroll yapılıyorsa (bunu kontrol etmek iyi olur ama zorunlu değil)
        if (index <= itemThreshold &&
            !_isLoadingPrev &&
            !_isInitialLoad &&
            _feedItems.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchPreviousBatch();
          });
        }

        // --- UI ÇİZİMİ (Mevcut kodun) ---

        // A. Bottom Loading Indicator
        if (index == _feedItems.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
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
    );
  }
}
