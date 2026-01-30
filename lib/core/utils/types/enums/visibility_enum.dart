enum VisibilityEnum {
  everyone._('everyone'),
  onlyFriends._('onlyFriends'),
  university._('university'),
  custom._('custom');

  const VisibilityEnum._(this.value);
  final String value;

  @override
  String toString() {
    switch (this) {
      case VisibilityEnum.everyone:
        return 'everyone';
      case VisibilityEnum.onlyFriends:
        return 'onlyFriends';
      case VisibilityEnum.university:
        return 'university';
      case VisibilityEnum.custom:
        return 'custom';
    }
  }
}
