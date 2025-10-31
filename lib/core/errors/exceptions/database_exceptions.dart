class DatabaseException implements Exception {
  DatabaseException(this.message);
  final String message;

  @override
  String toString() {
    return 'DatabaseException: $message';
  }
}

class EntryNotFoundException extends DatabaseException {
  EntryNotFoundException(super.message);
}
