abstract class FeedEntity {
  FeedEntity({
    required this.feedType,
  });
  final FeedEntityType feedType;
}

enum FeedEntityType {
  post,
  event,
}
