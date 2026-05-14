// core/utils/types/enums/feed_entity_type_enum.dart

enum FeedEntityTypeEnum {
  post._('post'),
  event._('event'),
  idea._('idea');

  const FeedEntityTypeEnum._(this.value);
  final String value;

  @override
  String toString() => value;

  static FeedEntityTypeEnum fromString(String value) {
    switch (value) {
      case 'post':
        return post;
      case 'event':
        return event;
      case 'idea':
        return idea;
      default:
        throw ArgumentError('Unknown feed entity type: $value');
    }
  }
}
