import 'dart:async';

import 'package:outnest/core/errors/exceptions/auth_exceptions.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/core/utils/validators/masks.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServiceImpl implements AuthService {
  AuthServiceImpl({
    required LoggingService logger,
    required FirebaseAuth firebaseAuth,
  }) : _logger = logger,
       _firebaseAuth = firebaseAuth;

  final LoggingService _logger;
  final FirebaseAuth _firebaseAuth;

  @override
  Identifier getCurrentUserID() {
    _logger.debug('getCurrentUserCredential called');

    if (_firebaseAuth.currentUser == null) {
      _logger.warn('getCurrentUserCredential: no current user');
      throw AuthException('No user is currently signed in.');
    }
    final uid = _firebaseAuth.currentUser!.uid;
    _logger.info('getCurrentUserCredential: userId=$uid');
    return uid;
  }

  @override
  Future<bool> isUserLoggedIn() {
    _logger.debug('isUserLoggedIn called');
    try {
      final loggedIn = _firebaseAuth.currentUser != null;
      _logger.info('isUserLoggedIn: $loggedIn');
      return Future.value(loggedIn);
    } on FirebaseAuthException catch (e) {
      _logger.error('isUserLoggedIn error: ${e.message}');
      throw AuthException('No user is currently signed in.');
    }
  }

  @override
  Future<PhoneAuthResult> resendSMS({
    required String phoneNumber,
    required int? resendToken,
  }) async {
    final completer = Completer<PhoneAuthResult>();
    _logger.debug(
      'resendSMS called for phone=${maskPhone(phoneNumber)}'
      ' resendToken=$resendToken',
    );
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: resendToken,
        verificationCompleted: (credential) async {
          _logger.info('resendSMS: verificationCompleted');
          final _ = await _firebaseAuth.signInWithCredential(credential);

          completer.complete(
            PhoneAuthResult(
              verificationId: credential.verificationId,
              isVerified: true,
            ),
          );
        },
        verificationFailed: (e) {
          _logger.error('resendSMS verificationFailed: ${e.message}');
          completer.complete(
            PhoneAuthResult(error: e.message, verificationId: null),
          );
        },
        codeSent: (verificationId, newResendToken) {
          _logger.info(
            'resendSMS codeSent verificationId=$verificationId'
            ' resendToken=$newResendToken',
          );
          completer.complete(
            PhoneAuthResult(
              verificationId: verificationId,
              resendToken: newResendToken,
            ),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!completer.isCompleted) {
            _logger.info(
              'resendSMS codeAutoRetrievalTimeout'
              ' verificationId=$verificationId',
            );
            completer.complete(
              PhoneAuthResult(
                verificationId: verificationId,
              ),
            );
          }
        },
      );
    } on FirebaseAuthException catch (e) {
      _logger.error('resendSMS exception: ${e.message}');
      completer.complete(
        PhoneAuthResult(
          verificationId: null,
          error: e.message,
        ),
      );
    }

    return completer.future;
  }

  @override
  Future<PhoneAuthResult> sendSMS({required String phoneNumber}) {
    final completer = Completer<PhoneAuthResult>();
    _logger.debug('sendSMS called for phone=${maskPhone(phoneNumber)}');

    try {
      _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _logger.info('sendSMS verificationCompleted');
          // Auto-retrieval or instant verification completed
          final result = await _firebaseAuth.signInWithCredential(credential);
          completer.complete(
            PhoneAuthResult(
              verificationId: result.user?.uid,
              isVerified: true,
            ),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          _logger.error('sendSMS verificationFailed: ${e.message}');
          // Verification failed
          completer.complete(
            PhoneAuthResult(
              verificationId: null,
              error: e.message,
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _logger.info(
            'sendSMS codeSent verificationId=$verificationId'
            ' resendToken=$resendToken',
          );
          // Code sent to the user's phone
          completer.complete(
            PhoneAuthResult(
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _logger.info(
            'sendSMS codeAutoRetrievalTimeout verificationId=$verificationId',
          );
          if (!completer.isCompleted) {
            completer.complete(
              PhoneAuthResult(
                verificationId: verificationId,
              ),
            );
          }
        },
      );
    } on FirebaseAuthException catch (e) {
      _logger.error('sendSMS exception: ${e.message}');
      completer.complete(
        PhoneAuthResult(
          verificationId: null,
          error: e.message,
        ),
      );
    }

    return completer.future;
  }

  @override
  Future<String> signInWithSms({
    required String verificationId,
    required String smsCode,
  }) async {
    // async ekledik
    _logger.debug('signInWithSms called verificationId=$verificationId');
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        // KRİTİK NOKTA: Token'ı zorla yenileyerek backend'in (Functions)
        // güncel session'ı tanımasını sağlıyoruz.
        await user.getIdToken(true);
        _logger.info('signInWithSms: success, userId=${user.uid}');
        return user.uid;
      } else {
        throw AuthException('Kullanıcı bilgisi alınamadı.');
      }
    } on FirebaseAuthException catch (e) {
      _logger.error('signInWithSms error: ${e.message}');
      throw AuthException(
        e.message ?? 'An unknown error occurred during SMS sign-in.',
      );
    }
  }

  @override
  Future<void> verifyAndChangePhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    _logger.debug('verifyAndChangePhoneNumber called');
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final user = _firebaseAuth.currentUser;
      if (user == null)
        throw AuthException('Oturum açmış kullanıcı bulunamadı.');

      // Bu metod mevcut kullanıcının telefon numarasını Auth üzerinde günceller
      await user.updatePhoneNumber(credential);

      _logger.info('Telefon numarası başarıyla güncellendi: ${user.uid}');
    } on FirebaseAuthException catch (e) {
      _logger.error('updatePhoneNumber error: ${e.code} - ${e.message}');
      // Örn: 'credential-already-in-use' hatası burada yakalanır
      throw AuthException(e.message ?? 'Numara güncellenirken hata oluştu.');
    }
  }

  @override
  Future<void> signOut() {
    _logger.debug('signOut called');
    try {
      if (_firebaseAuth.currentUser == null) {
        _logger.warn('signOut: no current user');
        throw AuthException('No user is currently signed in.');
      }
    } on FirebaseAuthException catch (e) {
      _logger.error('signOut error: ${e.message}');
      throw AuthException(
        e.message ?? 'An unknown error occurred during sign-out.',
      );
    }
    _logger.info('signOut: signing out user');
    return _firebaseAuth.signOut();
  }

  @override
  Future<String> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    _logger.debug('signInWithApple called');
    try {
      final result = await _firebaseAuth.signInWithProvider(appleProvider);
      final uid = result.user!.uid;
      _logger.info('signInWithApple: userId=$uid');

      return uid;
    } on FirebaseAuthException catch (e) {
      _logger.error('signInWithApple error: ${e.message}');
      throw AuthException(
        e.message ?? 'An unknown error occurred during Apple sign-in.',
      );
    }
  }

  @override
  Stream<String?> get onAuthStateChanged =>
      _firebaseAuth.authStateChanges().map((user) => user?.uid);

  @override
  String getUserPhoneNumber() {
    _logger.debug('getUserPhoneNumber called');

    final user = _firebaseAuth.currentUser;
    if (user == null) {
      _logger.warn('getUserPhoneNumber: no current user');
      throw AuthException('No user is currently signed in.');
    }

    final phoneNumber = user.phoneNumber;
    _logger.info(
      'getUserPhoneNumber: phone=${phoneNumber != null ? maskPhone(phoneNumber) : "null"}',
    );
    return phoneNumber ?? '';
  }
}
