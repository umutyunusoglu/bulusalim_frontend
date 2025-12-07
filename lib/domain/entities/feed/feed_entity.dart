abstract class FeedEntity {
  FeedEntity({
    required this.feedType,
    required this.id,
  });
  final String id;
  final FeedEntityType feedType;
}

enum FeedEntityType {
  post,
  event,
}
