import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:encrypt/encrypt.dart';
import 'package:outnest/core/errors/exceptions/security_exceptions.dart';
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
  }) : _sessionService = sessionService,
       _persistanceService = persistanceService;

  final SessionService _sessionService;
  final PersistanceService _persistanceService;
  static const String _verifiedEventsKey = 'verified_events_list';

  @override
  EventVerificationSecret createEventVerificationSecret(
    Geolocation currentLocation,
  ) {
    // Geohash the location with precision 6 -> 610 meters
    final geoHasher = GeoHasher();
    final geohash = geoHasher.encode(
      currentLocation.longitude,
      currentLocation.latitude,
      precision: 6,
    ); //abwx46

    if (_sessionService.currentUser == null) {
      throw AuthorizationException('User not logged in');
    }

    final currentUserID = _sessionService.currentUser!.userID;
    final message = currentUserID;

    // Generate the key for encryption
    // Key is 32 byte long string
    final key = _generateKey(currentUserID, geohash);

    // Encrypt the message with the key
    final encryptionResult = _encryptMessage(message, key);
    final encryptedMessage = encryptionResult['encrypted'];
    final iv = encryptionResult['iv'];

    // Create the secret using message and initialization vector
    final secret = '$encryptedMessage-$iv';

    return secret;
  }

  @override
  Future<bool> isEventVerified(EventEntity event) async {
    final data = await _persistanceService.getJson(_verifiedEventsKey);

    if (data == null || !data.containsKey('ids')) {
      return false;
    }

    final verifiedIds = List<String>.from(data['ids'] as List);
    return verifiedIds.contains(event.id);
  }

  @override
  Future<bool> verifyEvent(
    EventEntity event,
    Geolocation currentLocation,
    EventVerificationSecret secret,
  ) async {
    // Parse the secret int encrypted message and initialization vector
    final split = secret.split('-');
    final encryptedMessage = split[0];
    final iv = split[1];

    // Hash our location with precision 6 -> 610 meters
    final geohasher = GeoHasher();
    final myGehoash = geohasher.encode(
      currentLocation.longitude,
      currentLocation.latitude,
      precision: 6,
    );

    // In order to overcome border failures we consider 3x3 grid
    final possibleGeohashes = geohasher.neighbors(myGehoash);

    // Get the Ids of participants of the event
    final possibleUserIDs = event.participants
        .map((user) => user.userID)
        .toSet();

    // Try all possible users
    for (final userID in possibleUserIDs) {
      for (final geohash in possibleGeohashes.values) {
        final candidateKey = _generateKey(userID, geohash);
        final decryptedMessage = tryDecryptMessage(
          encryptedMessage,
          candidateKey,
          iv,
        );
        if (decryptedMessage != null && decryptedMessage == userID) {
          await _saveVerifiedEvent(event);
          return true;
        }
      }
    }
    return false;
  }

  String _generateKey(Identifier userID, String geohash) {
    final keyString = '$userID-$geohash';
    final keyBytes = utf8.encode(keyString);
    final key = sha256.convert(keyBytes).toString();
    return key;
  }

  Map<String, String> _encryptMessage(String message, String keyString) {
    final key = Key.fromBase16(keyString);
    final iv = IV.fromLength(16);

    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(message, iv: iv);

    return {
      'encrypted': encrypted.base64,
      'iv': iv.base64,
    };
  }

  String? tryDecryptMessage(
    String encryptedMessage,
    String keyString,
    String ivString,
  ) {
    try {
      final key = Key.fromBase16(keyString);
      final iv = IV.fromBase64(ivString);
      final encrypter = Encrypter(AES(key));
      final decrypted = encrypter.decrypt(
        Encrypted.fromBase64(encryptedMessage),
        iv: iv,
      );
      return decrypted;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveVerifiedEvent(EventEntity event) async {
    final data = await _persistanceService.getJson(_verifiedEventsKey);
    List<String> verifiedIds = [];

    if (data != null && data.containsKey('ids')) {
      verifiedIds = List<String>.from(data['ids'] as List);
    }

    if (!verifiedIds.contains(event.id)) {
      verifiedIds.add(event.id);
      await _persistanceService.saveJson(_verifiedEventsKey, {
        'ids': verifiedIds,
      });
    }
  }

  Future<void> clearExpiredVerifiedEvents() async {
    final data = await _persistanceService.getJson(_verifiedEventsKey);

    if (data == null || !data.containsKey('ids')) {
      return;
    }

    final verifiedIds = List<String>.from(data['ids'] as List);
    final idsToRemove = <String>[];

    final activeEventsIds = _sessionService.activeEvents.map((e) => e.eventID);
    for (final eventId in verifiedIds) {
      if (!activeEventsIds.contains(eventId)) {
        idsToRemove.add(eventId);
      }
    }

    if (idsToRemove.isEmpty) {
      return;
    }
    verifiedIds.removeWhere((id) => idsToRemove.contains(id));

    await _persistanceService.saveJson(_verifiedEventsKey, {
      'ids': verifiedIds,
    });
  }
}
