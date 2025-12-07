enum EventRoleEnum {
  organizer._('organizer'),
  participant._('participant');

  const EventRoleEnum._(this.value);

  final String value;

  @override
  String toString() => value;

  static EventRoleEnum fromString(String value) {
    switch (value) {
      case 'organizer':
        return organizer;
      case 'participant':
        return participant;
      default:
        throw ArgumentError('Unknown event role: $value');
    }
  }
}
