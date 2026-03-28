import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';

/// Streams the list of events that are currently ongoing for the current user.
///
/// Returns an empty list if the user is not authenticated.
/// Auto-disposes when no longer listened to.
final StreamProvider<List<EventEntity>> ongoingEventsProvider =
    StreamProvider.autoDispose<List<EventEntity>>((
      ref,
    ) {
      final userID = ref.watch(currentUserIDProvider);
      if (userID == null) return Stream.value([]);

      return getIt<UserRepository>().watchOngoingEvents(userID);
    });

final Provider<bool> isUserInOngoingEventProvider = Provider.autoDispose<bool>((
  ref,
) {
  final ongoingEvents = ref.watch(ongoingEventsProvider).value ?? [];
  return ongoingEvents.isNotEmpty;
});

/// Streams the list of events that are scheduled in the future for the current user.
///
/// Returns an empty list if the user is not authenticated.
/// Auto-disposes when no longer listened to.
final StreamProvider<List<EventEntity>> upcomingEventsProvider =
    StreamProvider.autoDispose<List<EventEntity>>((ref) {
      final userID = ref.watch(currentUserIDProvider);
      if (userID == null) return Stream.value([]);

      return getIt<UserRepository>().watchUpcomingEvents(userID);
    });

/// Combines [ongoingEventsProvider] and [upcomingEventsProvider] into a single
/// flat list of all active events (ongoing + upcoming) for the current user.
///
/// Auto-disposes when no longer listened to.
final Provider<List<EventEntity>> activeEventsProvider =
    Provider.autoDispose<List<EventEntity>>((ref) {
      final ongoing = ref.watch(ongoingEventsProvider).value ?? [];
      final upcoming = ref.watch(upcomingEventsProvider).value ?? [];
      return [...ongoing, ...upcoming];
    });
