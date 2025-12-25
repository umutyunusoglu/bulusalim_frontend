enum EventStatusEnum {
  saved._('saved'),
  pending._('pending'),
  rejected._('rejected'),
  upcoming._('upcoming'),
  ongoing._('ongoing'),
  completed._('completed'),
  cancelled._('cancelled');

  const EventStatusEnum._(this.value);
  final String value;

  @override
  String toString() => value;

  static EventStatusEnum fromString(String value) {
    switch (value) {
      case 'pending':
        return pending;
      case 'rejected':
        return rejected;
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
