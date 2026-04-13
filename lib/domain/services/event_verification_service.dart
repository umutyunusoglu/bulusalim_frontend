import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';

/// Alias for the string that is used to verify events.
typedef EventVerificationSecret = String;

abstract class EventVerificationService {
  /// Given an event, the current location of verifier and verification secret,
  /// Verifies whether current user is at the same event as the creator
  /// Of the Secret
  Future<bool> verifyEvent(
    EventEntity event,
    Geolocation currentLocation,
    EventVerificationSecret secret,
  );

  /// Generates a new event verification secret for the given event
  /// Secret can be used the verify that the verifier is at the same event with
  /// The creator of the secret
  EventVerificationSecret createEventVerificationSecret(
    Geolocation currentLocation,
  );

  /// Using local storage check whether the given event is verified by the
  /// Current User
  Future<bool> isEventVerified(EventEntity event);

  Future<void> markEventAsVerifiedForDebug(EventEntity event);
}
