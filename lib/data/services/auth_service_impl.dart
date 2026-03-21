import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart' hide GoogleSignInException;
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/core/errors/exceptions/auth_exceptions.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/core/utils/validators/masks.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
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
  Either<AuthNotFoundException, Identifier> getCurrentUserID() {
    _logger.debug('getCurrentUserCredential called');

    if (_firebaseAuth.currentUser == null) {
      _logger.warn('getCurrentUserCredential: no current user');
      return left(
        AuthNotFoundException('Giriş yapmış bir kullanıcı bulunamadı.'),
      );
    }
    final uid = _firebaseAuth.currentUser!.uid;
    _logger.info('getCurrentUserCredential: userId=$uid');

    return right(uid);
  }

  @override
  TaskEither<AuthException, PhoneAuthResult> resendSMS({
    required String phoneNumber,
    required int? resendToken,
  }) {
    return TaskEither.tryCatch(
      () async {
        final completer = Completer<PhoneAuthResult>();
        _logger.debug(
          'resendSMS called for phone=${maskPhone(phoneNumber)}'
          ' resendToken=$resendToken',
        );

        await _firebaseAuth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          forceResendingToken: resendToken,
          verificationCompleted: (credential) async {},
          verificationFailed: (e) {
            _logger.error('resendSMS verificationFailed: ${e.message}');
            if (!completer.isCompleted) {
              completer.completeError(
                OTPSendException(
                  'SMS tekrar gönderilirken bir hata oluştu, lütfen başka bir giriş yöntemi deneyiniz.',
                ),
              );
            }
          },
          codeSent: (verificationId, newResendToken) {
            _logger.info(
              'resendSMS codeSent verificationId=$verificationId'
              ' resendToken=$newResendToken',
            );
            if (!completer.isCompleted) {
              completer.complete(
                PhoneAuthResult(
                  verificationId: verificationId,
                  resendToken: newResendToken,
                ),
              );
            }
          },
          codeAutoRetrievalTimeout: (verificationId) {
            _logger.info(
              'resendSMS codeAutoRetrievalTimeout'
              ' verificationId=$verificationId',
            );
            if (!completer.isCompleted) {
              completer.completeError(
                SMSTimeoutException('SMS zaman aşımına uğradı'),
              );
            }
          },
        );

        return completer.future;
      },
      (error, stack) {
        _logger.error('resendSMS exception: $error');
        if (error is AuthException) return error;
        return OTPSendException('SMS tekrar gönderilemedi: $error');
      },
    );
  }

  @override
  TaskEither<AuthException, PhoneAuthResult> sendSMS({
    required String phoneNumber,
  }) {
    return TaskEither.tryCatch(
      () async {
        final completer = Completer<PhoneAuthResult>();
        _logger.debug('sendSMS called for phone=${maskPhone(phoneNumber)}');

        await _firebaseAuth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: const Duration(seconds: 90),
          verificationCompleted: (credential) async {},
          verificationFailed: (e) {
            _logger.error('sendSMS verificationFailed: ${e.message}');
            if (!completer.isCompleted) {
              completer.completeError(
                OTPSendException(e.message ?? 'SMS doğrulama başarısız'),
              );
            }
          },
          codeSent: (verificationId, resendToken) {
            _logger.info('sendSMS codeSent verificationId=$verificationId');
            if (!completer.isCompleted) {
              completer.complete(
                PhoneAuthResult(
                  verificationId: verificationId,
                  resendToken: resendToken,
                ),
              );
            }
          },
          codeAutoRetrievalTimeout: (verificationId) {
            _logger.info('sendSMS codeAutoRetrievalTimeout');
            if (!completer.isCompleted) {
              completer.completeError(
                SMSTimeoutException('SMS zaman aşımına uğradı'),
              );
            }
          },
        );

        return completer.future;
      },
      (error, stack) {
        _logger.error('sendSMS exception: $error');
        if (error is AuthException) return error;
        return OTPSendException(
          'SMS gönderilirken bilinmeyen bir hata oluştu.',
        );
      },
    );
  }

  @override
  TaskEither<AuthException, String> signInWithSms({
    required String verificationId,
    required String smsCode,
    required bool isLogin,
  }) {
    return TaskEither.tryCatch(
      () async {
        _logger.debug('signInWithSms called (isLogin: $isLogin)');

        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );

        final userCredential = await _firebaseAuth.signInWithCredential(
          credential,
        );

        final user = userCredential.user;

        if (user == null) {
          throw VerificationTokenException('Kullanıcı doğrulanamadı.');
        }

        final userRepository = getIt<UserRepository>();
        final isNewUser = !await userRepository.isUserRegistered(user.uid);

        if (isLogin && isNewUser) {
          await user.delete();
          throw AuthNotFoundException(
            'Bu numara ile kayıtlı bir hesap bulunamadı.',
          );
        }

        if (!isLogin && !isNewUser) {
          throw UserAlreadyExistsException(
            'Bu telefon numarası zaten kullanımda. Giriş yapmayı deneyin.',
          );
        }

        await user.getIdToken(true);
        return user.uid;
      },
      (error, stack) {
        _logger.error('signInWithSms error: $error');
        if (error is AuthException) return error;
        return VerificationTokenException('Doğrulama hatası: $error');
      },
    );
  }

  @override
  TaskEither<AuthException, void> verifyAndChangePhoneNumber({
    required String verificationId,
    required String smsCode,
  }) {
    return TaskEither.tryCatch(
      () async {
        _logger.debug('verifyAndChangePhoneNumber called');

        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );

        final user = _firebaseAuth.currentUser;

        if (user == null) {
          throw AuthNotFoundException('Oturum açmış kullanıcı bulunamadı.');
        }

        await user.updatePhoneNumber(credential);
        _logger.info('Telefon numarası başarıyla güncellendi: ${user.uid}');
      },
      (error, stack) {
        _logger.error('verifyAndChangePhoneNumber error: $error');
        if (error is AuthException) return error;
        return OTPVerificationException('Numara güncellenirken hata: $error');
      },
    );
  }

  @override
  TaskEither<AuthException, void> signOut() {
    return TaskEither.tryCatch(
      () async {
        _logger.debug('signOut called');

        final user = _firebaseAuth.currentUser;
        if (user == null) {
          _logger.warn('signOut: no current user');
          throw AuthNotFoundException('Oturum açmış kullanıcı bulunamadı.');
        }

        _logger.info('signOut: signing out user');
        await _firebaseAuth.signOut();
      },
      (error, stack) {
        _logger.error('signOut error: $error');
        if (error is AuthException) return error;
        return UnknownAuthException('Çıkış yapılırken bir hata oluştu: $error');
      },
    );
  }

  @override
  TaskEither<AuthException, String> signInWithApple({
    required bool isLogin,
  }) {
    return TaskEither.tryCatch(
      () async {
        _logger.debug('signInWithApple called (isLogin: $isLogin)');

        final appleProvider = AppleAuthProvider()
          ..addScope('email')
          ..addScope('name');

        final userCredential = await _firebaseAuth.signInWithProvider(
          appleProvider,
        );

        final user = userCredential.user;

        if (user == null) {
          throw AppleSignInException(
            'Apple servisinden kullanıcı verisi alınamadı.',
          );
        }

        final userRepository = getIt<UserRepository>();
        final isNewUser = !await userRepository.isUserRegistered(user.uid);

        if (isLogin && isNewUser) {
          _logger.warn(
            'Login attempt with new Apple account. Deleting user...',
          );
           _cleanupUser(user);
          throw AuthNotFoundException(
            'Apple hesabınızla ilişkili bir kayıt bulunamadı. Lütfen önce kayıt olun.',
          );
        }

        if (!isLogin && !isNewUser) {
          _logger.info('Register attempt with existing Apple account.');
          throw UserAlreadyExistsException(
            'Bu Apple hesabı zaten kullanımda. Lütfen giriş yapın.',
          );
        }

        await user.getIdToken(true);
        return user.uid;
      },
      (error, stack) {
        _logger.error('signInWithApple error: $error');
        if (error is AuthException) return error;
        if (error is FirebaseAuthException) {
          if (error.code == 'canceled' || error.code == 'user-cancelled') {
            return AuthCancelledException('İşlem iptal edildi.');
          }
          return AppleSignInException(
            error.message ?? 'Apple girişi sırasında bir hata oluştu.',
          );
        }
        return AppleSignInException('Beklenmedik bir hata oluştu: $error');
      },
    );
  }


  @override
  TaskEither<AuthException, String> signInWithGoogle({
    required bool isLogin,
  }) {
    return TaskEither.tryCatch(
      () async {
        _logger.debug('signInWithGoogle called (isLogin: $isLogin)');

        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        final userCredential = await _firebaseAuth.signInWithCredential(
          credential,
        );

        final user = userCredential.user;

        if (user == null) {
          throw GoogleSignInException(
            'Google servisinden kullanıcı verisi alınamadı.',
          );
        }

        await _validateLoginRegister(
          user: user,
          isLogin: isLogin,
          providerName: 'Google',
        );

        _logger.info('signInWithGoogle success: ${user.uid}');
        await user.getIdToken(true);
        return user.uid;
      },
      (error, stack) {
        _logger.error('signInWithGoogle error: $error');
        if (error is AuthException) return error;
        if (error is FirebaseAuthException) {
          if (error.code == 'canceled' || error.code == 'user-cancelled') {
            return AuthCancelledException('İşlem iptal edildi.');
          }
          return GoogleSignInException(
            error.message ?? 'Google girişi sırasında bir hata oluştu.',
          );
        }
        return GoogleSignInException('Google işlemi başarısız: $error');
      },
    );
  }

  @override
  Stream<String?> get onAuthStateChanged =>
      _firebaseAuth.authStateChanges().map((user) => user?.uid);
  @override
  Either<AuthException, String> getUserPhoneNumber() {
    _logger.debug('getUserPhoneNumber called');

    final user = _firebaseAuth.currentUser;

    if (user == null) {
      _logger.warn('getUserPhoneNumber: no current user');
      return Left(AuthNotFoundException('Oturum açmış kullanıcı bulunamadı.'));
    }

    final phoneNumber = user.phoneNumber ?? '';
    _logger.info(
      'getUserPhoneNumber: phone=${phoneNumber.isNotEmpty ? maskPhone(phoneNumber) : "boş"}',
    );
    return Right(phoneNumber);
  }


TaskEither<AuthException, void> _cleanupUser(User user) {
  return TaskEither.tryCatch(
    () => user.delete(),
    (error, stack) {
      _logger.error('Kullanıcı silinemedi: $error');
      return UnknownAuthException('Geçici kullanıcı temizlenemedi.');
    },
  ).orElse(
    // delete başarısız olursa signOut dene
    (_) => TaskEither.tryCatch(
      () => _firebaseAuth.signOut(),
      (error, stack) {
        _logger.error('Oturum da kapatılamadı: $error');
        return UnknownAuthException('Oturum kapatılamadı.');
      },
    ),
  );
}
  // ortak kontrol
  Future<void> _validateLoginRegister({
    required User user,
    required bool isLogin,
    required String providerName,
  }) async {
    final userRepository = getIt<UserRepository>();
    final isNewUser = !await userRepository.isUserRegistered(user.uid);

    if (isLogin && isNewUser) {
      await _cleanupUser(user).run();
      throw AuthNotFoundException(
        '$providerName hesabınızla ilişkili bir kayıt bulunamadı.',
      );
    }

    if (!isLogin && !isNewUser) {
      throw UserAlreadyExistsException(
        'Bu $providerName hesabı zaten kullanımda. Lütfen giriş yapın.',
      );
    }
  }
}
