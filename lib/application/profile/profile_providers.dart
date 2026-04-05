import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_friend_providers.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/user_event_status_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/user_event_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/repositories/user_repository.dart';

// ─── Helpers ────────────────────────────────────────────────

bool _isTransientError(Object error) {
  if (error is FirebaseException && error.code == 'unavailable') return true;
  final msg = error.toString().toLowerCase();
  return msg.contains('cloud_firestore/unavailable') ||
      msg.contains('unknownhostexception') ||
      msg.contains('unable to resolve host') ||
      msg.contains('socketexception');
}

Future<T> _withRetry<T>(
  Future<T> Function() action, {
  required String label,
  int maxAttempts = 3,
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await action();
    } catch (e) {
      if (!_isTransientError(e) || attempt == maxAttempts) rethrow;
      getIt<LoggingService>().warn(
        'Profile retry ($attempt/$maxAttempts) for $label: $e',
      );
      await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
    }
  }
  throw StateError('Unreachable retry state for $label');
}

Future<T> _withFallback<T>(
  Future<T> Function() action, {
  required String label,
  required T fallback,
}) async {
  try {
    return await _withRetry(action, label: label);
  } catch (e) {
    getIt<LoggingService>().warn('Profile fallback used for $label: $e');
    return fallback;
  }
}

// ─── Providers ──────────────────────────────────────────────

/// Profil kullanıcı verisi (kendi profilse currentUserEntity, değilse Firestore'dan)
final FutureProviderFamily<dynamic, String> profileUserProvider = FutureProvider
    .autoDispose
    .family<dynamic, String>((ref, profileUserID) async {
      final myUserId = ref.watch(currentUserIDProvider);
      if (profileUserID == myUserId) {
        return ref.watch(currentUserEntityProvider).value;
      }
      return _withRetry(() async {
        //stale
        final user = await getIt<UserRepository>().getUserPublicData(
          profileUserID,
        );
        if (user == null) {
          throw StateError('Public user is null for $profileUserID');
        }
        return user;
      }, label: 'getUserPublicData');
    });

/// Kullanıcı postları stream'i — pinned ve active olarak ayrılmış
final StreamProviderFamily<
  ({List<PostEntity> active, List<PostEntity> pinned}),
  String
>
profilePostsProvider = StreamProvider.autoDispose
    .family<({List<PostEntity> pinned, List<PostEntity> active}), String>((
      ref,
      userId,
    ) {
      return getIt<UserRepository>().getUserPostsStream(userId).map((allPosts) {
        final pinned = allPosts.where((p) => p.isPinned).toList();
        final active = allPosts.where((p) => !p.isPinned).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return (pinned: pinned, active: active);
      });
    });

/// Takip durumu
final FutureProviderFamily<
  ({bool hasSentFollowRequest, bool isFollowing}),
  String
>
profileFollowStatusProvider = FutureProvider.autoDispose
    .family<({bool isFollowing, bool hasSentFollowRequest}), String>((
      ref,
      profileUserID,
    ) async {
      final myUserId = ref.watch(currentUserIDProvider);
      if (myUserId == null) {
        // Unauthenticated users are not following and have no pending follow request
        return (isFollowing: false, hasSentFollowRequest: false);
      }
      if (profileUserID == myUserId) {
        // Viewing own profile: always treated as following, no follow request
        return (isFollowing: true, hasSentFollowRequest: false);
      }

      final userRepo = getIt<UserRepository>();

      final isFollowing = await _withFallback(
        () => userRepo.isFollowing(myUserId, profileUserID),
        label: 'isFollowing',
        fallback: false,
      );

      var hasSentFollowRequest = false;
      if (!isFollowing) {
        hasSentFollowRequest = await _withFallback(
          () => userRepo.hasSentFollowRequest(myUserId, profileUserID),
          label: 'hasSentFollowRequest',
          fallback: false,
        );
      }

      return (
        isFollowing: isFollowing,
        hasSentFollowRequest: hasSentFollowRequest,
      );
    });

/// İstatistikler (takipçi, takip, buluşma sayısı)
final FutureProviderFamily<({int events, int followers, int following}), String>
profileStatsProvider = FutureProvider.autoDispose
    .family<({int followers, int following, int events}), String>((
      ref,
      profileUserID,
    ) async {
      final userRepo = getIt<UserRepository>();

      final results = await Future.wait([
        _withFallback(
          () => userRepo.getFollowersCount(profileUserID),
          label: 'getFollowersCount',
          fallback: 0,
        ),
        _withFallback(
          () => userRepo.getFolloweesCount(profileUserID),
          label: 'getFolloweesCount',
          fallback: 0,
        ),
        _withFallback(
          () => userRepo.getCompletedEventCount(profileUserID),
          label: 'getCompletedEventCount',
          fallback: 0,
        ),
      ]);

      return (followers: results[0], following: results[1], events: results[2]);
    });

//TODO: Eğer benim profilimse, kendi streamlerime göre getir!
/// Etkinlikler (kayıtlı + kaydedilenler)
final FutureProviderFamily<
  ({List<EventEntity> considered, List<EventEntity> current}),
  String
>
profileEventsProvider = FutureProvider.autoDispose
    .family<
      ({List<EventEntity> current, List<EventEntity> considered}),
      String
    >((ref, profileUserID) async {
      final userRepo = getIt<UserRepository>();
      final eventRepo = getIt<EventRepository>();

      final userEvents = await _withFallback<List<UserEventEntity>>(
        () => userRepo.getUserEventLog(profileUserID),
        label: 'getUserEventLog',
        fallback: <UserEventEntity>[],
      );

      final enrolledIds = <Identifier>[];
      final savedIds = <Identifier>[];

      for (final event in userEvents) {
        switch (event.status) {
          case UserEventStatusEnum.upcoming:
          case UserEventStatusEnum.ongoing:
            enrolledIds.add(event.eventId);
            break;
          case UserEventStatusEnum.saved:
            savedIds.add(event.eventId);
            break;
          default:
            break;
        }
      }

      var enrolledEvents = <EventEntity>[];
      if (enrolledIds.isNotEmpty) {
        enrolledEvents = await _withFallback(
          () => eventRepo.getEventsByIds(enrolledIds),
          label: 'getEnrolledEvents',
          fallback: <EventEntity>[],
        );
      }

      var savedEvents = <EventEntity>[];
      if (savedIds.isNotEmpty) {
        savedEvents = await _withFallback(
          () => eventRepo.getEventsByIds(savedIds),
          label: 'getSavedEvents',
          fallback: <EventEntity>[],
        );
      }

      return (current: enrolledEvents, considered: savedEvents);
    });

/// Ortak takipçiler
final FutureProviderFamily<List<CompactUserEntity>, String>
profileCommonFollowersProvider = FutureProvider.autoDispose
    .family<List<CompactUserEntity>, String>((ref, profileUserID) async {
      final myUserId = ref.watch(currentUserIDProvider);
      if (myUserId == null || profileUserID == myUserId) return [];

      final myFollowers = ref.watch(currentUserFollowersProvider).value ?? [];
      final userRepo = getIt<UserRepository>();
      final commonFollows = <CompactUserEntity>[];

      for (final follower in myFollowers) {
        final follows = await _withFallback(
          () => userRepo.isFollowing(profileUserID, follower.userID),
          label: 'isFollowingCommon:${follower.userID}',
          fallback: false,
        );
        if (follows) commonFollows.add(follower);
      }

      return commonFollows;
    });
