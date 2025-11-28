enum LifestyleEnum {
  never._('never'),
  social._('social'),
  regular._('regular');

  const LifestyleEnum._(this.value);
  final String value;

  @override
  String toString() => value;

  static LifestyleEnum fromString(String value) {
    switch (value) {
      case 'never':
        return never;
      case 'social':
        return social;
      case 'regular':
        return regular;
      default:
        throw Exception('Unknown lifestyle: $value');
    }
  }
}
