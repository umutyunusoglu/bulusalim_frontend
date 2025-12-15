enum EventStatusEnum {
  upcoming._('upcoming'),
  saved._('saved'),
  ongoing._('ongoing'),
  completed._('completed'),
  cancelled._('cancelled');

  const EventStatusEnum._(this.value);
  final String value;

  @override
  String toString() => value;

  static EventStatusEnum fromString(String value) {
    switch (value) {
      case 'upcoming':
        return upcoming;
      case 'ongoing':
        return ongoing;
      case 'completed':
        return completed;
      case 'cancelled':
        return cancelled;
      case 'saved':
        return saved;
      default:
        throw ArgumentError('Unknown event status: $value');
    }
  }
}
