enum GenderEnum {
  male._('male'),
  female._('female'),
  other._('other');

  const GenderEnum._(this.value);

  final String value;

  @override
  String toString() => value;

  static GenderEnum fromString(String value) {
    switch (value) {
      case 'male':
        return male;
      case 'female':
        return female;
      case 'other':
        return other;
      default:
        throw ArgumentError('Unknown gender: $value');
    }
  }
}
