// lib/domain/repositories/auth_repository.dart

import 'package:outnest/core/errors/exceptions/auth_exceptions.dart';
import 'package:outnest/core/utils/types/types.dart';

abstract class AuthService {
  Future<PhoneAuthResult> sendSMS({required String phoneNumber});
  Future<PhoneAuthResult> resendSMS({
    required String phoneNumber,
    required int? resendToken,
  });

  Future<String> signInWithSms({
    required String verificationId,
    required String smsCode,
    required bool isLogin,
  });

  Future<void> verifyAndChangePhoneNumber({
    required String verificationId,
    required String smsCode,
  });

  Future<String> signInWithApple({required bool isLogin});
  Future<String> signInWithGoogle({required bool isLogin});

  /// Gets the current user's ID. 
  /// Throws [AuthException] if no user is signed in.
  Identifier getCurrentUserID();
  Stream<String?> get onAuthStateChanged;

  Future<void> signOut();

  String getUserPhoneNumber();
}

class PhoneAuthResult {
  PhoneAuthResult({
    required this.verificationId,
    this.resendToken,
    this.isVerified = false,
    this.error,
  });
  final String? verificationId;
  final bool isVerified;
  final String? error;

  final int? resendToken;
}
