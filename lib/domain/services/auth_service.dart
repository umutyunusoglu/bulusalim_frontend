import 'package:fpdart/fpdart.dart';
import 'package:outnest/core/errors/exceptions/auth_exceptions.dart';
import 'package:outnest/core/utils/types/types.dart';

abstract class AuthService {
  /// Sends an SMS verification code to the given phone number.
  /// Returns [PhoneAuthResult] on success.
  /// Left: [OTPSendException], [SMSTimeoutException].
  TaskEither<AuthException, PhoneAuthResult> sendSMS({
    required String phoneNumber,
  });

  /// Resends an SMS verification code using the previous resend token.
  /// Returns [PhoneAuthResult] on success.
  /// Left: [OTPSendException], [SMSTimeoutException].
  TaskEither<AuthException, PhoneAuthResult> resendSMS({
    required String phoneNumber,
    required int? resendToken,
  });

  /// Signs in with an SMS code and returns the user uid.
  /// Left: [VerificationTokenException] if verification fails,
  /// [AuthNotFoundException] if login with unregistered number,
  /// [UserAlreadyExistsException] if register with existing number.
  TaskEither<AuthException, String> signInWithSms({
    required String verificationId,
    required String smsCode,
    required bool isLogin,
  });

  /// Updates the current user's phone number after SMS verification.
  /// Left: [AuthNotFoundException] if no user is signed in,
  /// [OTPVerificationException] if verification fails.
  TaskEither<AuthException, void> verifyAndChangePhoneNumber({
    required String verificationId,
    required String smsCode,
  });

  /// Signs in with Apple and returns the user uid.
  /// Left: [AuthCancelledException] if user cancels,
  /// [AuthNotFoundException] if login with unregistered account,
  /// [UserAlreadyExistsException] if register with existing account,
  /// [AppleSignInException] on other failures.
  TaskEither<AuthException, String> signInWithApple({
    required bool isLogin,
  });

  /// Signs in with Google and returns the user uid.
  /// Left: [AuthCancelledException] if user cancels,
  /// [AuthNotFoundException] if login with unregistered account,
  /// [UserAlreadyExistsException] if register with existing account,
  /// [GoogleSignInException] on other failures.
  TaskEither<AuthException, String> signInWithGoogle({
    required bool isLogin,
  });

  /// Returns the current user's uid.
  /// Left: [AuthNotFoundException] if no user is signed in.
  Either<AuthNotFoundException, Identifier> getCurrentUserID();

  /// Returns the current user's phone number.
  /// Left: [AuthNotFoundException] if no user is signed in.
  Either<AuthException, String> getUserPhoneNumber();

  /// Signs the current user out.
  /// Left: [AuthNotFoundException] if no user is signed in.
  TaskEither<AuthException, void> signOut();

  /// Emits the current user's uid on auth state changes, or null if signed out.
  Stream<String?> get onAuthStateChanged;
}

class PhoneAuthResult {
  PhoneAuthResult({
    required this.verificationId,
    this.resendToken,
  });

  final String verificationId;
  final int? resendToken;
}