enum FeedType {
  all._('all'),
  friendsOnly._('friendsOnly'),
  university._('university');

  const FeedType._(this.value);
  final String value;

  @override
  String toString() => value;

  static FeedType fromString(String value) {
    switch (value) {
      case 'university':
        return university;
      case 'friendsOnly':
        return friendsOnly;
      case 'all':
        return all;
      default:
        throw ArgumentError('Unknown feed type: $value');
    }
  }
}
