class EventVerificationException implements Exception {
  EventVerificationException(this.message);
  final String message;

  @override
  String toString() {
    return 'EventVerificationException  : $message';
  }
}

class EventMismatchException extends EventVerificationException {
  EventMismatchException(super.message);
}

class LocationMismatchException extends EventVerificationException {
  LocationMismatchException(super.message);
}

class UnknownVerificationException extends EventVerificationException {
  UnknownVerificationException(super.message);
}
