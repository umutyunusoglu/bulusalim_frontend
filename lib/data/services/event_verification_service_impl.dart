import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:encrypt/encrypt.dart';
import 'package:outnest/core/errors/exceptions/security_exceptions.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/event_verification_service.dart';
import 'package:outnest/domain/services/persistance_service.dart';
import 'package:outnest/domain/services/session_service.dart';

class EventVerificationServiceImpl implements EventVerificationService {
  EventVerificationServiceImpl({
    required SessionService sessionService,
    required PersistanceService persistanceService,
    required LoggingService logger,
  }) : _sessionService = sessionService,
       _persistanceService = persistanceService,
       _loggingService = logger;

  final SessionService _sessionService;
  final PersistanceService _persistanceService;
  final LoggingService _loggingService;
  static const String _verifiedEventsKey = 'verified_events_list';

  @override
  EventVerificationSecret createEventVerificationSecret(
    Geolocation currentLocation,
  ) {
    if (_sessionService.currentUser == null) {
      _loggingService.error('Secret creation failed: User not logged in');
      throw AuthorizationException('User not logged in');
    }

    try {
      final geoHasher = GeoHasher();
      final geohash = geoHasher.encode(
        currentLocation.longitude,
        currentLocation.latitude,
        precision: 6,
      );

      final currentUserID = _sessionService.currentUser!.userID;
      final key = _generateKey(currentUserID, geohash);
      final encryptionResult = _encryptMessage(currentUserID, key);

      final secret =
          '${encryptionResult['encrypted']}-${encryptionResult['iv']}';

      _loggingService.info(
        'Verification secret created for user: $currentUserID at geohash: $geohash',
      );
      return secret;
    } catch (e, stackTrace) {
      _loggingService.error(
        'Failed to create event verification secret',
      );
      throw Exception('Failed to create event verification secret: $e');
    }
  }

  @override
  Future<bool> isEventVerified(EventEntity event) async {
    try {
      final data = await _persistanceService.getJson(_verifiedEventsKey);
      if (data == null || !data.containsKey('ids')) return false;

      final verifiedIds = List<String>.from(data['ids'] as List);
      final isVerified = verifiedIds.contains(event.id);

      if (isVerified) {
        _loggingService.debug(
          'Event ${event.id} is already verified in local storage.',
        );
      }

      return isVerified;
    } catch (e) {
      _loggingService.warn(
        'Error checking event verification status for ${event.id}: $e',
      );
      return false;
    }
  }

  @override
  Future<bool> verifyEvent(
    EventEntity event,
    Geolocation currentLocation,
    EventVerificationSecret secret,
  ) async {
    try {
      final split = secret.split('-');
      if (split.length != 2) {
        _loggingService.warn(
          'Invalid secret format received for event: ${event.id}',
        );
        throw const FormatException(
          'Invalid event verification secret format.',
        );
      }

      final encryptedMessage = split[0];
      final iv = split[1];

      final geohasher = GeoHasher();
      final myGeohash = geohasher.encode(
        currentLocation.longitude,
        currentLocation.latitude,
        precision: 6,
      );

      // Komşu geohash'leri ve ana geohash'i alıyoruz (3x3 grid)
      final allCandidateGeohashes = geohasher.neighbors(myGeohash).values;

      final possibleUserIDs = event.participants
          .map((user) => user.userID)
          .toSet();

      _loggingService.debug(
        'Attempting verification for event ${event.id} across ${allCandidateGeohashes.length} geohashes',
      );

      for (final userID in possibleUserIDs) {
        for (final geohash in allCandidateGeohashes) {
          final candidateKey = _generateKey(userID, geohash);
          final decryptedMessage = _tryDecryptMessage(
            encryptedMessage,
            candidateKey,
            iv,
          );
          final myUserID = _sessionService.currentUser?.userID;

          if (decryptedMessage != null &&
              decryptedMessage == userID &&
              userID != myUserID) {
            _loggingService.info(
              'Event ${event.id} successfully verified by matching user $userID at geohash $geohash',
            );
            await _saveVerifiedEvent(event);
            return true;
          }
        }
      }

      _loggingService.warn(
        'Verification failed for event ${event.id}: No matching key found in 3x3 grid.',
      );
      return false;
    } on FormatException catch (e) {
      _loggingService.error('Format error during verification');
      rethrow;
    } catch (e, stackTrace) {
      _loggingService.error(
        'Unexpected error during event verification',
      );
      throw Exception('An error occurred during event verification: $e');
    }
  }

  // --- Private Helpers with Logging ---

  String _generateKey(Identifier userID, String geohash) {
    try {
      final keyString = '$userID-$geohash';
      final keyBytes = utf8.encode(keyString);
      return sha256.convert(keyBytes).toString();
    } catch (e) {
      _loggingService.error(
        'Key generation failed',
      );
      throw Exception('Failed to generate encryption key');
    }
  }

  Map<String, String> _encryptMessage(String message, String keyString) {
    try {
      final key = Key.fromBase16(keyString);
      final iv = IV.fromLength(
        16,
      ); // Rastgele IV üretimi (Güvenlik için önemli)
      final encrypter = Encrypter(AES(key));
      final encrypted = encrypter.encrypt(message, iv: iv);

      return {
        'encrypted': encrypted.base64,
        'iv': iv.base64,
      };
    } catch (e) {
      _loggingService.error('Encryption operation failed');
      throw Exception('Encryption failed: $e');
    }
  }

  String? _tryDecryptMessage(
    String encryptedMessage,
    String keyString,
    String ivString,
  ) {
    try {
      final key = Key.fromBase16(keyString);
      final iv = IV.fromBase64(ivString);
      final encrypter = Encrypter(AES(key));
      return encrypter.decrypt(Encrypted.fromBase64(encryptedMessage), iv: iv);
    } catch (_) {
      // Brute-force denemelerinde bu hata beklenen bir durumdur, loglamaya gerek yok.
      return null;
    }
  }

  Future<void> _saveVerifiedEvent(EventEntity event) async {
    try {
      final data = await _persistanceService.getJson(_verifiedEventsKey);
      List<String> verifiedIds = (data != null && data.containsKey('ids'))
          ? List<String>.from(data['ids'] as List)
          : [];

      if (!verifiedIds.contains(event.id)) {
        verifiedIds.add(event.id);
        await _persistanceService.saveJson(_verifiedEventsKey, {
          'ids': verifiedIds,
        });
        _loggingService.info('Event ${event.id} saved to local verified list.');
      }
    } catch (e) {
      _loggingService.error('Failed to persist verified event ${event.id}');
    }
  }
}
