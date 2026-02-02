import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _feedRepository
      ..switchFeedType(widget.feedType)
      ..refresh();

    // 2. Scroll dinleyicisi (Pagination için)
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Listenin sonuna yaklaşıldı mı?
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
              // +1 ekleyerek en alta loading indicator koyabiliriz (opsiyonel)
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                if (item is PostEntity) {
                  // Postlar genelde statik kalabilir (beğeni anlık değilse)
                  return PostCard(post: item, user: item.creator);
                } else if (item is EventEntity) {
                  // KRİTİK NOKTA: Event kartını "Canlı" moda alıyoruz.
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

// --- Event Canlılığı İçin Özel Widget ---
// Bu widget, listedeki tek bir event kartını sarmalar ve
// sadece o kartın verisini canlı tutar.
class _LiveEventItem extends StatelessWidget {
  final EventEntity initialEvent;
  final FeedRepository repository;

  const _LiveEventItem({
    required this.initialEvent,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FeedEntity>(
      // Repository'den o eventin özel stream'ini istiyoruz
      stream: repository.getLiveEventStream(initialEvent.eventID),
      // Ekrana ilk geldiğinde bekleme yapmaması için listeden gelen veriyi kullanıyoruz
      initialData: initialEvent,
      builder: (context, snapshot) {
        // Stream'den gelen en güncel veri (yoksa initial'ı kullan)
        final liveData = (snapshot.data as EventEntity?) ?? initialEvent;

        return EventCard(
          event: liveData,
          participants: liveData.participants,
        );
      },
    );
  }
}
