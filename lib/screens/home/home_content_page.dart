import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/post_card.dart';
import 'package:bulusalim/core/enums/feed_type.dart';
import 'package:bulusalim/domain/entities/post/post_entity.dart';
import 'package:bulusalim/domain/repositories/post_repository.dart';
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

  final PostRepository _postRepository = getIt<PostRepository>();

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    try {
      var posts = <PostEntity>[];
      // List<EventEntity> events = [];

      if (widget.feedType == FeedType.forYou) {
        posts = await _postRepository.getAllPosts();
      } else if (widget.feedType == FeedType.friendsOnly) {
        posts = await _postRepository.getAllPosts();
      }

      final List<Object> combinedList = [];
      combinedList.addAll(posts);
      // combinedList.addAll(events);

      if (mounted) {
        setState(() {
          _feedItems = combinedList;
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
          return PostCard(post: item);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
