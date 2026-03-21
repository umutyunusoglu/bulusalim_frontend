sealed class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() {
    return message;
  }
}

class UnknownAuthException extends AuthException {
  UnknownAuthException(super.message);
}

class OTPSendException extends AuthException {
  OTPSendException(super.message);
}

class OTPVerificationException extends AuthException {
  OTPVerificationException(super.message);
}

class VerificationTokenException extends OTPVerificationException {
  VerificationTokenException(super.message);
}

class AuthNotFoundException extends AuthException {
  AuthNotFoundException(super.message);
}

class ExistingUserNotFoundException extends AuthException {
  ExistingUserNotFoundException(super.message);
}

class UserAlreadyExistsException extends AuthException {
  UserAlreadyExistsException(super.message);
}

class SMSTimeoutException extends AuthException {
  SMSTimeoutException(super.message);
}

class AuthCancelledException extends AuthException {
  AuthCancelledException(super.message);
}

class AppleAuthException extends AuthException {
  AppleAuthException(super.message);
}

class GoogleAuthException extends AuthException {
  GoogleAuthException(super.message);
}
