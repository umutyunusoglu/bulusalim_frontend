enum CapabilityEnum {
  photo._('photo');

  const CapabilityEnum._(this.value);
  final String value;
  @override
  String toString() => value;

  static CapabilityEnum fromString(String value) {
    switch (value) {
      case 'photo':
        return photo;
      default:
        throw Exception('Unknown capability: $value');
    }
  }
}
