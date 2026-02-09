import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:outnest/core/errors/exceptions/auth_exceptions.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/core/utils/validators/masks.dart';
import 'package:outnest/domain/services/auth_service.dart';

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
  Future<bool> isUserLoggedIn() async {
    _logger.debug('isUserLoggedIn called');
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      _logger.info('isUserLoggedIn: false (no local user)');
      return false;
    }

    try {
      // Backend ile senkronize olur. Hesap silindiyse burada hata fırlatır.
      await user.reload();
      _logger.info('isUserLoggedIn: true (verified)');
      return true;
    } catch (e) {
      _logger.error('isUserLoggedIn error (user likely deleted/disabled): $e');
      // Eğer reload başarısız olursa kullanıcı artık geçerli değildir.
      return false;
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
        timeout: const Duration(seconds: 180),

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
    required bool isLogin,
  }) async {
    _logger.debug('signInWithSms called (isLogin: $isLogin)');
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
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        // Login'de yeni kullanıcıyı engelle
        if (isLogin && isNewUser) {
          await user.delete();
          throw AuthException('Bu numara ile kayıtlı bir hesap bulunamadı.');
        }

        // Kayıtta eski kullanıcıyı engelle
        if (!isLogin && !isNewUser) {
          throw AuthException(
            'Bu telefon numarası zaten kullanımda. Giriş yapmayı deneyin.',
          );
        }

        await user.getIdToken(true);
        return user.uid;
      }
      throw AuthException('Kullanıcı doğrulanamadı.');
    } on FirebaseAuthException catch (e) {
      _logger.error('signInWithSms error: ${e.message}');
      throw AuthException(e.message ?? 'Doğrulama hatası.');
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
      if (user == null) {
        throw AuthException('Oturum açmış kullanıcı bulunamadı.');
      }

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
  Future<String> signInWithApple({required bool isLogin}) async {
    _logger.debug('signInWithApple called (isLogin: $isLogin)');
    try {
      final appleProvider = AppleAuthProvider();

      // Apple'dan e-posta ve isim izinlerini de isteyelim (İlk kayıtta lazım olur)
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      final userCredential = await _firebaseAuth.signInWithProvider(
        appleProvider,
      );
      final user = userCredential.user;

      if (user != null) {
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        // 1. Giriş ekranında yeni kullanıcı gelirse:
        if (isLogin && isNewUser) {
          _logger.warn(
            'Login attempt with new Apple account. Deleting user...',
          );
          try {
            await user.delete();
          } catch (e) {
            _logger.error('Failed to delete temporary Apple user: $e');
            // Silinemezse bile en azından oturumu kapatıp hata fırlatalım
            await _firebaseAuth.signOut();
          }
          throw AuthException(
            'Apple hesabınızla ilişkili bir kayıt bulunamadı. Lütfen önce kayıt olun.',
          );
        }

        // 2. Kayıt ekranında mevcut kullanıcı gelirse:
        if (!isLogin && !isNewUser) {
          _logger.info('Register attempt with existing Apple account.');
          throw AuthException(
            'Bu Apple hesabı zaten kullanımda. Lütfen giriş yapın.',
          );
        }
        await user.getIdToken(true);
        return user.uid;
      }
      throw AuthException('Apple servisinden kullanıcı verisi alınamadı.');
    } on FirebaseAuthException catch (e) {
      _logger.error('signInWithApple FirebaseAuthException: ${e.code}');

      // Kullanıcı işlemi iptal ettiyse (Vazgeç'e bastıysa)
      if (e.code == 'canceled' || e.code == 'user-cancelled') {
        throw AuthException('İşlem iptal edildi.');
      }

      throw AuthException(
        e.message ?? 'Apple girişi sırasında bir hata oluştu.',
      );
    } catch (e) {
      _logger.error('signInWithApple unexpected error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Beklenmedik bir hata oluştu.');
    }
  }

  @override
  Future<String> signInWithGoogle({required bool isLogin}) async {
    _logger.debug('signInWithGoogle called (isLogin: $isLogin)');
    try {
      // --- SENİN VERDİĞİN TASLAK ---
      // Trigger the authentication flow

      final googleUser = await GoogleSignIn.instance.authenticate();

      if (googleUser == null) throw AuthException('Giriş iptal edildi.');

      // Obtain the auth details from the request
      final googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Once signed in, get the UserCredential
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      // --- TASLAK SONU ---

      final user = userCredential.user;

      if (user != null) {
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        // 1. Giriş sayfasında yeni kullanıcı engelleme
        if (isLogin && isNewUser) {
          _logger.warn('Login attempt with new account. Deleting...');
          await user.delete();
          throw AuthException('Hesabınız bulunamadı. Lütfen kayıt olun.');
        }

        // 2. Kayıt sayfasında eski kullanıcı engelleme
        if (!isLogin && !isNewUser) {
          _logger.info('Register attempt with existing account.');
          throw AuthException('Bu hesap zaten kayıtlı. Lütfen giriş yapın.');
        }

        _logger.info('signInWithGoogle success: ${user.uid}');
        await user.getIdToken(true);
        return user.uid;
      }
      throw AuthException('Kullanıcı verisi alınamadı.');
    } catch (e) {
      _logger.error('signInWithGoogle error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Google işlemi başarısız.: $e');
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
