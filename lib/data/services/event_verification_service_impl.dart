import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:fpdart/fpdart.dart';
import 'package:outnest/core/errors/exceptions/event_verification_exceptions.dart';
import 'package:outnest/core/errors/exceptions/security_exceptions.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/services/event_verification_service.dart';
import 'package:outnest/domain/services/persistance_service.dart';

class EventVerificationServiceImpl implements EventVerificationService {
  EventVerificationServiceImpl({
    required this.currentUserId,
    required PersistanceService persistanceService,
    required LoggingService logger,
    required EventRepository eventRepository,
  }) : _persistanceService = persistanceService,
       _loggingService = logger,
       _eventRepository = eventRepository;

  final String? currentUserId;
  final PersistanceService _persistanceService;
  final LoggingService _loggingService;
  final EventRepository _eventRepository;

  static const String _verifiedEventsKey = 'verified_events_list';
  static const double _maxDistanceMeters = 1000;

  @override
  EventVerificationSecret createEventVerificationSecret(
    Geolocation currentLocation,
  ) {
    if (currentUserId == null) {
      _loggingService.error('Secret creation failed: User not logged in');
      throw AuthorizationException('User not logged in');
    }

    try {
      final message =
          '$currentUserId:${currentLocation.latitude}:${currentLocation.longitude}';

      final key = _generateKey(currentUserId!);
      final encryptionResult = _encryptMessage(message, key);

      final secret =
          '${encryptionResult['encrypted']}||${encryptionResult['iv']}';

      _loggingService.info(
        'Verification secret created for user: $currentUserId',
      );
      return secret;
    } catch (e) {
      _loggingService.error('Failed to create event verification secret');
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
  Future<Either<EventVerificationException, Unit>> verifyEvent(
    EventEntity event,
    Geolocation currentLocation,
    EventVerificationSecret secret,
  ) async {
    try {
      _loggingService.debug('Raw secret: $secret');

      final split = secret.split('||');
      if (split.length != 2) {
        _loggingService.warn(
          'Invalid secret format received for event: ${event.id}',
        );
        return Left(
          UnknownVerificationException(
            'Invalid event verification secret format.',
          ),
        );
      }

      final encryptedMessage = split[0];
      final iv = split[1];

      final possibleUserIDs = event.participants
          .map((user) => user.userID)
          .toSet();

      _loggingService.debug(
        'Attempting verification for event ${event.id} with ${possibleUserIDs.length} participants',
      );

      for (final userID in possibleUserIDs) {
        if (userID == currentUserId) continue;

        final candidateKey = _generateKey(userID);
        final decryptedMessage = _tryDecryptMessage(
          encryptedMessage,
          candidateKey,
          iv,
        );

        if (decryptedMessage == null) continue;

        // userId:lat:lon formatını parse et
        final parts = decryptedMessage.split(':');
        if (parts.length != 3) continue;

        final decryptedUserId = parts[0];
        final lat = double.tryParse(parts[1]);
        final lon = double.tryParse(parts[2]);

        if (decryptedUserId != userID || lat == null || lon == null) continue;

        // Mesafe kontrolü
        final distance = _calculateDistanceMeters(
          currentLocation.latitude,
          currentLocation.longitude,
          lat,
          lon,
        );

        _loggingService.debug(
          'Decrypted location for $userID: $lat, $lon — distance: ${distance.toStringAsFixed(0)}m',
        );

        if (distance <= _maxDistanceMeters) {
          _loggingService.info(
            'Event ${event.id} verified: matched user $userID at ${distance.toStringAsFixed(0)}m',
          );
          await _saveVerifiedEvent(event);
          return const Right(unit);
        } else {
          _loggingService.warn(
            'Verification failed for event ${event.id}: Location mismatch (${distance.toStringAsFixed(0)}m)',
          );
          return Left(
            LocationMismatchException(
              'Konumunuz QR kodunu oluşturan kişiyle uyuşmuyor. (${distance.toStringAsFixed(0)}m uzaktasınız)',
            ),
          );
        }
      }

      _loggingService.warn(
        'Verification failed for event ${event.id}: No matching participant found.',
      );
      return Left(
        EventMismatchException(
          'Bu QR kodu bu etkinliğe ait değil.',
        ),
      );
    } catch (e) {
      _loggingService.error('Unexpected error during event verification: $e');
      return Left(
        UnknownVerificationException(
          'Doğrulama sırasında beklenmeyen bir hata oluştu.',
        ),
      );
    }
  }

  // Geohash yerine sadece userId ile key üret
  String _generateKey(Identifier userID) {
    try {
      final keyBytes = utf8.encode(userID);
      return sha256.convert(keyBytes).toString();
    } catch (e) {
      _loggingService.error('Key generation failed');
      throw Exception('Failed to generate encryption key');
    }
  }

  // Haversine formülü — metre cinsinden mesafe
  double _calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;

  Map<String, String> _encryptMessage(String message, String keyString) {
    try {
      final key = Key.fromBase16(keyString);
      final iv = IV.fromLength(16);
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
      return null;
    }
  }

  Future<void> _saveVerifiedEvent(EventEntity event) async {
    try {
      final data = await _persistanceService.getJson(_verifiedEventsKey);
      final verifiedIds = (data != null && data.containsKey('ids'))
          ? List<String>.from(data['ids'] as List)
          : <String>[];

      if (!verifiedIds.contains(event.id)) {
        verifiedIds.add(event.id);
        await _persistanceService.saveJson(_verifiedEventsKey, {
          'ids': verifiedIds,
        });
        _loggingService.info('Event ${event.id} saved to local verified list.');
      }

      if (currentUserId != null) {
        await _eventRepository.markEventAsVerified(
          eventId: event.id,
          userId: currentUserId!,
        );
      }
    } catch (e) {
      _loggingService.error('Failed to persist verified event ${event.id}');
    }
  }

  @override
  Future<void> markEventAsVerifiedForDebug(EventEntity event) async {
    if (currentUserId == null) {
      throw AuthorizationException('User not logged in');
    }
    await _saveVerifiedEvent(event);
  }
}
