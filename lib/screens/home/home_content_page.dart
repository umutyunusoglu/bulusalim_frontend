import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/event_card.dart';
import 'package:bulusalim/components/post_card.dart';
import 'package:bulusalim/core/constants/Configs/app_config.dart';
import 'package:bulusalim/core/enums/feed_type.dart';
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

  List<FeedEntity> _feedItems = [];
  bool _isLoadingNext = false;
  bool _isLoadingPrev = false;
  bool _isInitialLoad = true;

  final double _scrollThreshold = 800.0; // Veri çekme tetikleme eşiği

  final _feedRepository = getIt<FeedRepository>();

  @override
  void initState() {
    super.initState();
    // 1. Scroll Dinleyici
    _scrollController.addListener(_onScroll);
    // 2. İlk Veri Çekme
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

    // 1. Aşağı Kaydırma (Eski gönderileri getir)
    if (currentScroll >= (maxScroll - _scrollThreshold) && !_isLoadingNext) {
      _fetchNextBatch();
    }

    // 2. Yukarı Kaydırma (Yeni gönderileri getir - Opsiyonel)
    if (currentScroll <= _scrollThreshold && !_isLoadingPrev) {
      _fetchPreviousBatch();
    }
  }

  Future<void> _fetchInitial() async {
    try {
      final newItems = await _feedRepository.fetchNextFeedBatch(null);

      if (mounted) {
        setState(() {
          _feedItems = newItems;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      debugPrint("Initial fetch error: $e");
      if (mounted) setState(() => _isInitialLoad = false);
    }
  }

  Future<void> _fetchNextBatch() async {
    setState(() => _isLoadingNext = true);

    try {
      final lastPost = _feedItems.isNotEmpty ? _feedItems.last : null;
      final newItems = await _feedRepository.fetchNextFeedBatch(lastPost);

      if (mounted && newItems.isNotEmpty) {
        setState(() {
          _feedItems.addAll(newItems);
        });
      }
    } catch (e) {
      debugPrint("Error fetching next: $e");
    } finally {
      if (mounted) setState(() => _isLoadingNext = false);
    }
  }

  Future<void> _fetchPreviousBatch() async {
    // Spam engelleme
    if (_feedItems.isEmpty) return;

    setState(() => _isLoadingPrev = true);

    try {
      final firstPost = _feedItems.first;
      final newItems = await _feedRepository.fetchPreviousFeedBatch(firstPost);

      if (mounted && newItems.isNotEmpty) {
        // --- SCROLL POZİSYONUNU KORUMA ---
        // Üste eleman eklenince liste kaymasın diye scroll'u düzeltiyoruz.
        double previousHeight = _scrollController.position.maxScrollExtent;

        setState(() {
          _feedItems.insertAll(0, newItems);
        });

        // Frame çizildikten sonra scroll'u eski konumuna zıplat
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final newHeight = _scrollController.position.maxScrollExtent;
            final double heightDifference = newHeight - previousHeight;
            _scrollController.jumpTo(
              _scrollController.offset + heightDifference,
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching previous: $e");
    } finally {
      if (mounted) setState(() => _isLoadingPrev = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Yükleniyor Durumu
    if (_isInitialLoad) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    // 2. Boş Durum (Empty State)
    if (_feedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feed_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "Henüz içerik yok.",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    const itemThreshold = AppConfig.feedFetchThreshold;

    return ListView.builder(
      controller: _scrollController,
      // Altta loading varsa +1 ekle
      itemCount: _feedItems.length + (_isLoadingNext ? 1 : 0),
      itemBuilder: (context, index) {
        // --- OTOMATİK YÜKLEME TETİKLEYİCİLERİ (Fallback) ---

        // Listenin sonuna yaklaşıldı mı?
        if (index >= _feedItems.length - itemThreshold &&
            !_isLoadingNext &&
            !_isInitialLoad) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchNextBatch();
          });
        }

        // Listenin başına yaklaşıldı mı?
        if (index <= itemThreshold &&
            !_isLoadingPrev &&
            !_isInitialLoad &&
            _feedItems.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchPreviousBatch();
          });
        }

        // --- UI ÇİZİMİ ---

        // A. Alt Loading İndikatörü
        if (index == _feedItems.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator.adaptive()),
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

        return const SizedBox.shrink(); // Bilinmeyen tip
      },
    );
  }
}
