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
    final lowercase = value.toLowerCase().trim();
    switch (lowercase) {
      case 'male' || 'erkek':
        return male;
      case 'female' || 'kadın':
        return female;
      case 'other' || 'diğer':
        return other;
      case 'preferNotToSay' || 'belirtmek istemiyorum':
        return preferNotToSay;
      default:
        throw ArgumentError('Unknown gender: $value');
    }
  }
}
