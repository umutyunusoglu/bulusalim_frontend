enum EventRoleEnum {
  creator._('creator'),
  participant._('participant');

  const EventRoleEnum._(this.value);

  final String value;

  @override
  String toString() => value;

  static EventRoleEnum fromString(String value) {
    switch (value) {
      case 'creator':
        return creator;
      case 'participant':
        return participant;
      default:
        throw ArgumentError('Unknown event role: $value');
    }
  }
}
