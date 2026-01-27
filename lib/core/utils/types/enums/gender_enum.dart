enum GenderEnum {
  male._('Erkek'),
  female._('Kadın'),
  other._('Diğer'),
  preferNotToSay._('Belirtmek İstemiyorum');

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
      case 'preferNotToSay':
        return preferNotToSay;
      default:
        throw ArgumentError('Unknown gender: $value');
    }
  }
}
