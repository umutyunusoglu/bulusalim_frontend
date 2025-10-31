class SecurityException implements Exception {
  SecurityException(this.message);
  final String message;

  @override
  String toString() {
    return 'SecurityException: $message';
  }
}

class AuthorizationException implements SecurityException {
  AuthorizationException(this.message);
  @override
  final String message;

  @override
  String toString() {
    return 'AuthenticationException: $message';
  }
}
