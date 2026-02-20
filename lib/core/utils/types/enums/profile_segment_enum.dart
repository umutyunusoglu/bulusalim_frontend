enum ProfileSegmentEnum {
  home._('posts'),
  search._('events'),
  profile._('dumps');

  const ProfileSegmentEnum._(this.value);
  final String value;

  @override
  String toString() => value;

  static ProfileSegmentEnum fromString(String value) {
    switch (value) {
      case 'posts':
        return home;
      case 'events':
        return search;
      case 'dumps':
        return profile;
      default:
        throw ArgumentError('Unknown profile segment: $value');
    }
  }
}
