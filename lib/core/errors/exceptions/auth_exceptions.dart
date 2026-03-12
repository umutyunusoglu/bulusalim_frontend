class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() {
    return '$message';
  }
}

class OTPSendException extends AuthException {
  OTPSendException(super.message);
}

class OTPVerificationException extends AuthException {
  OTPVerificationException(super.message);
}

class VerificationTokenError extends OTPVerificationException {
  VerificationTokenError(super.message);
}
