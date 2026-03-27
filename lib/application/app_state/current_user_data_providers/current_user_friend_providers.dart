import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';

/// Streams the list of users that the current user is following.
/// Emits an empty list if the current user is not authenticated.
final StreamProvider<List<CompactUserEntity>> currentUserFolloweesProvider =
    StreamProvider.autoDispose<List<CompactUserEntity>>((ref) {
      final userID = ref.watch(currentUserIDProvider);
      if (userID == null) return Stream.value([]);

      return getIt<UserRepository>().watchFollowees(userID);
    });

/// Provides a flat list of user IDs that the current user is following.
/// Returns an empty list while the followees stream is loading or on error.
final Provider<List<Identifier>> currentUserFolloweeIDsProvider =
    Provider.autoDispose<List<Identifier>>((ref) {
      final followeesAsync = ref.watch(currentUserFolloweesProvider);
      return followeesAsync.maybeWhen(
        data: (followees) => followees.map((f) => f.userID).toList(),
        orElse: () => [],
      );
    });

/// Provides the number of users the current user is following.
/// Returns 0 while the followees stream is loading or on error.
final Provider<int> currentUserFolloweeCountProvider =
    Provider.autoDispose<int>((ref) {
      final followeesAsync = ref.watch(currentUserFolloweesProvider);
      return followeesAsync.maybeWhen(
        data: (followees) => followees.length,
        orElse: () => 0,
      );
    });

/// Streams the list of users who are following the current user.
/// Emits an empty list if the current user is not authenticated.
final StreamProvider<List<CompactUserEntity>> currentUserFollowersProvider =
    StreamProvider.autoDispose<List<CompactUserEntity>>((ref) {
      final userID = ref.watch(currentUserIDProvider);
      if (userID == null) return Stream.value([]);

      return getIt<UserRepository>().watchFollowers(userID);
    });

/// Provides a flat list of user IDs who are following the current user.
/// Returns an empty list while the followers stream is loading or on error.
final Provider<List<Identifier>> currentUserFollowerIDsProvider =
    Provider.autoDispose<List<Identifier>>((ref) {
      final followersAsync = ref.watch(currentUserFollowersProvider);
      return followersAsync.maybeWhen(
        data: (followers) => followers.map((f) => f.userID).toList(),
        orElse: () => [],
      );
    });

/// Provides the number of users who are following the current user.
/// Returns 0 while the followers stream is loading or on error.
final Provider<int> currentUserFollowerCountProvider =
    Provider.autoDispose<int>((ref) {
      final followersAsync = ref.watch(currentUserFollowersProvider);
      return followersAsync.maybeWhen(
        data: (followers) => followers.length,
        orElse: () => 0,
      );
    });
