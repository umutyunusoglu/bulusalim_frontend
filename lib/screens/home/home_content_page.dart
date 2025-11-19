import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/event_card.dart';
import 'package:bulusalim/components/post_card.dart';
import 'package:bulusalim/core/enums/feed_type.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:bulusalim/domain/feed/event/event_entity.dart';
import 'package:bulusalim/domain/feed/post/post_entity.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
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
  bool _isLoading = true;
  String? _error;

  List<Object> _feedItems = [];
  Map<String, UserEntity> _userMap = {};
  final PostRepository _postRepository = getIt<PostRepository>();
  final EventRepository _eventRepository = getIt<EventRepository>();
  final UserRepository _userRepository = getIt<UserRepository>();

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    try {
      // 1. Post'ları ve Event'leri Çek
      List<PostEntity> posts = [];
      List<EventEntity> events = [];

      if (widget.feedType == FeedType.forYou) {
        posts = await _postRepository.getAllPosts();
      } else if (widget.feedType == FeedType.friendsOnly) {
        posts = await _postRepository.getAllPosts();
      }
      events = await _eventRepository.getAllEvents();

      // 2. Gerekli Tüm Benzersiz UserID'leri Topla
      // Set kullanarak her ID'nin sadece bir kez eklenmesini sağla
      final allUserIds = <String>{};

      // Post sahiplerinin ID'leri
      for (final post in posts) {
        allUserIds.add(post.userID);
      }

      // Event katılımcılarının ID'leri
      for (final event in events) {
        allUserIds.addAll(event.participants);
      }

      // 3. Tüm Kullanıcıları Tek Seferde (Paralel) Çek
      final userFutures = allUserIds
          .map((id) => _userRepository.getUser(id))
          .toList();
      final users = await Future.wait(userFutures);

      // 4. Kullanıcıları Hızlı Erişim İçin Bir Haritaya Yerleştir
      final newUserMap = <String, UserEntity>{};
      for (final user in users) {
        if (user != null) {
          newUserMap[user.userID] = user;
        }
      }

      // 5. Feed Listesini Oluştur ve Sırala
      final combinedList = <Object>[]
        ..addAll(posts)
        ..addAll(events)
        ..sort((a, b) {
          DateTime dateA;
          DateTime dateB;

          if (a is PostEntity) {
            dateA = a.createdAt;
          } else if (a is EventEntity) {
            dateA = a.createdAt;
          } else {
            return 0;
          }

          if (b is PostEntity) {
            dateB = b.createdAt;
          } else if (b is EventEntity) {
            dateB = b.createdAt;
          } else {
            return 0;
          }
          return dateB.compareTo(dateA);
        });

      if (mounted) {
        setState(() {
          _feedItems = combinedList;
          _userMap = newUserMap;
          _isLoading = false;
          _error = null;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Akış yüklenemedi:\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_feedItems.isEmpty) {
      return const Center(child: Text('Gösterilecek hiçbir şey yok.'));
    }

    return ListView.builder(
      itemCount: _feedItems.length,
      itemBuilder: (context, index) {
        final item = _feedItems[index];

        if (item is PostEntity) {
          // Post'un sahibinin UserEntity'sini haritadan bul
          final user = _userMap[item.userID];
          return PostCard(post: item, user: user);
        }

        if (item is EventEntity) {
          // Event'in katılımcılarının UserEntity'lerini haritadan bul
          final participantUsers = item.participants
              .map((id) => _userMap[id]) // Haritadan UserEntity'yi al
              .whereType<UserEntity>() // Null olanları filtrele
              .toList();

          return EventCard(event: item, participants: participantUsers);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
