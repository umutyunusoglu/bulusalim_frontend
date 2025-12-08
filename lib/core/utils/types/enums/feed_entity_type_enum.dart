enum FeedEntityTypeEnum {
  post._('post'),
  event._('event');

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
      default:
        throw ArgumentError('Unknown feed entity type: $value');
    }
  }
}
