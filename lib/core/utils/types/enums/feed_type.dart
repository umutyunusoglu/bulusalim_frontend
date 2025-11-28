enum FeedType {
  forYou._('forYou'),
  friendsOnly._('friendsOnly'),
  all._('all');

  const FeedType._(this.value);
  final String value;

  @override
  String toString() => value;

  static FeedType fromString(String value) {
    switch (value) {
      case 'forYou':
        return forYou;
      case 'friendsOnly':
        return friendsOnly;
      case 'all':
        return all;
      default:
        throw ArgumentError('Unknown feed type: $value');
    }
  }
}
