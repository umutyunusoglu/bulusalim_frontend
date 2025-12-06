// lib/domain/repositories/auth_repository.dart

import 'package:bulusalim/core/utils/types/types.dart';

abstract class AuthService {
  Future<PhoneAuthResult> sendSMS({required String phoneNumber});
  Future<PhoneAuthResult> resendSMS({
    required String phoneNumber,
    required int? resendToken,
  });

  Future<String> signInWithSms({
    required String verificationId,
    required String smsCode,
  });

  Future<String> signInWithApple();

  Identifier getCurrentUserID();
  Stream<String?> get onAuthStateChanged;

  Future<void> signOut();
  Future<bool> isUserLoggedIn();
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
