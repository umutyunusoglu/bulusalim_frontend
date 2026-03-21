enum ScreenEnum {
  home._('home'),
  search._('search'),
  profile._('profile'),
  chat._('chat'),
  notifications._('notifications'),
  settings._('settings'),
  map._('map'),
  communityDetail._('communityDetail');

  const ScreenEnum._(this.value);
  final String value;

  @override
  String toString() => value;

  static ScreenEnum fromString(String value) {
    switch (value) {
      case 'home':
        return home;
      case 'search':
        return search;
      case 'profile':
        return profile;
      case 'chat':
        return chat;
      case 'notifications':
        return notifications;
      case 'settings':
        return settings;
      case 'map':
        return map;
      case 'communityDetail':
        return communityDetail;
      default:
        throw ArgumentError('Unknown screen: $value');
    }
  }
}
