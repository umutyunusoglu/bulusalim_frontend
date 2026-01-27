import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/event_card.dart';
import 'package:outnest/components/post_card.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/repositories/feed_repository.dart';
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

  final int _nextPageThreshold = AppConfig.feedFetchThreshold;

  bool _hasMoreData = true;

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
    if (_feedItems.isEmpty) {
      setState(() => _isInitialLoad = true);
    }

    _hasMoreData = true;

    try {
      final newItems = await _feedRepository.fetchNextFeedBatch(null);

      if (mounted) {
        setState(() {
          _feedItems = newItems;
          _isInitialLoad = false;
          _isLoadingNext = false;
        });
      }
    } on Exception {
      // Hata yönetimi (Loglama vs.)
      if (mounted) setState(() => _isInitialLoad = false);
    }
  }

  Future<void> _fetchNextBatch() async {
    if (_isLoadingNext || !_hasMoreData) return;

    setState(() => _isLoadingNext = true);

    try {
      final lastItem = _feedItems.last;
      // Backend'den yeni veri iste
      final newItems = await _feedRepository.fetchNextFeedBatch(lastItem);

      if (mounted) {
        // ÇÖZÜM BURADA:
        // Gelen yeni listedeki her bir elemanın ID'sine bak,
        // eğer bu ID zaten mevcut listemizde (_feedItems) varsa, onu filtrele.
        final uniqueNewItems = newItems.where((newItem) {
          // any: "listede bu şartı sağlayan herhangi biri var mı?"
          final isAlreadyInList = _feedItems.any(
            (existingItem) => existingItem.id == newItem.id,
          );
          return !isAlreadyInList; // Listede YOKSA al, varsa alma.
        }).toList();

        if (uniqueNewItems.isNotEmpty) {
          // Sadece gerçekten YENİ olanları ekle
          setState(() {
            _feedItems.addAll(uniqueNewItems);
          });
        } else {
          // Eğer newItems dolu geldiyse ama hepsi zaten bizde varsa (uniqueNewItems boşsa),
          // demek ki backend başa sardı veya aynılarını yolluyor.
          // Sonsuz döngüyü kırmak için "veri bitti" diyoruz.
          setState(() => _hasMoreData = false);
        }
      }
    } on Exception {
      // Hata yönetimi
    } finally {
      if (mounted) setState(() => _isLoadingNext = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_feedItems.isEmpty) {
      // Empty state widget'ın
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Henüz içerik yok.'),
            ElevatedButton(
              onPressed: _fetchInitial,
              child: const Text('Yenile'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchInitial,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _feedItems.length + (_isLoadingNext ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _feedItems.length - _nextPageThreshold &&
              !_isLoadingNext &&
              _hasMoreData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchNextBatch();
            });
          }

          if (index == _feedItems.length) {
            return const Padding(
              padding: EdgeInsets.only(top: 36),
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
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
