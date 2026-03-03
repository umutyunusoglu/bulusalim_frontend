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

  static VisibilityEnum fromString(String value) {
    switch (value) {
      case 'everyone':
        return VisibilityEnum.everyone;
      case 'onlyFriends':
        return VisibilityEnum.onlyFriends;
      case 'university':
        return VisibilityEnum.university;
      case 'custom':
        return VisibilityEnum.custom;
      default:
        throw ArgumentError('Invalid visibility value: $value');
    }
  }

  static VisibilityEnum fromTurkishUI(String value) {
    switch (value.toLowerCase()) {
      case 'herkes':
        return VisibilityEnum.everyone;
      case 'takipçiler':
        return VisibilityEnum.onlyFriends;

      case 'arkadaşlar': // Mapping both to onlyFriends based on your list
        return VisibilityEnum.custom;
      case 'okul':
        return VisibilityEnum.university;
      default:
        return VisibilityEnum.everyone; // Fallback
    }
  }
}
