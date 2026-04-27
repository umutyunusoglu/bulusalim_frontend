import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_friend_providers.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/application/profile/profile_providers.dart';
import 'package:outnest/domain/entities/user/friend_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/share_links_service.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';
import 'package:riverpod/src/providers/notifier.dart';

class ProfileActionState {
  const ProfileActionState({this.hasSentFollowRequest = false});

  final bool hasSentFollowRequest;

  ProfileActionState copyWith({bool? hasSentFollowRequest}) {
    return ProfileActionState(
      hasSentFollowRequest: hasSentFollowRequest ?? this.hasSentFollowRequest,
    );
  }
}

class ProfileActionNotifier extends Notifier<ProfileActionState> {
  ProfileActionNotifier(this.profileUserID);

  final String profileUserID;

  @override
  ProfileActionState build() => const ProfileActionState();

  /// Takip et / takibi bırak
  Future<void> toggleFollow(
    BuildContext context, {
    required String username,
    required String profileImageUrl,
  }) async {
    final userRepository = getIt<UserRepository>();
    final currentUser = ref.read(currentUserEntityProvider).value;
    if (currentUser == null) return;

    final followees = ref.read(currentUserFolloweesProvider).value ?? [];
    final isCurrentlyFollowing = followees.any(
      (f) => f.userID == profileUserID,
    );

    try {
      if (!isCurrentlyFollowing) {
        final me = Follower(
          userID: currentUser.userID,
          username: currentUser.username,
          profileImageUrl: currentUser.profileImageUrl,
          createdAt: DateTime.now(),
        );
        final target = Followee(
          userID: profileUserID,
          username: username,
          profileImageUrl: profileImageUrl,
          createdAt: DateTime.now(),
        );
        await userRepository.addFollowee(currentUser.userID, target);
        await userRepository.addFollower(profileUserID, me);
      } else {
        await userRepository.removeFollowee(
          currentUser.userID,
          profileUserID,
        );
        await userRepository.removeFollower(
          profileUserID,
          currentUser.userID,
        );
      }

      invalidateProfileData();
    } catch (e) {
      debugPrint('Takip işlemi başarısız: $e');
      if (context.mounted) {
        showErrorPopup(
          context,
          message: 'İşlem başarısız oldu, lütfen tekrar deneyin.',
        );
      }
    }
  }

  /// Takip isteği gönder / iptal et (özel hesaplar için)
  Future<void> sendFollowRequest() async {
    final userRepository = getIt<UserRepository>();
    final myUserId = ref.read(currentUserIDProvider);
    if (myUserId == null) return;

    final previous = state;
    state = state.copyWith(hasSentFollowRequest: !state.hasSentFollowRequest);

    try {
      if (state.hasSentFollowRequest) {
        await userRepository.sendFollowRequest(
          myUserId,
          profileUserID,
          false,
        );
      } else {
        await userRepository.cancelFollowRequest(
          myUserId,
          profileUserID,
        );
      }
    } catch (_) {
      state = previous;
    }
  }

  /// Profil paylaş
  Future<void> shareProfile(BuildContext context, String userId) async {
    try {
      await getIt<ShareLinksService>().shareUserProfile(userId);
    } catch (e) {
      if (context.mounted) {
        showErrorPopup(
          context,
          message:
              'Profil paylaşılırken bir hata oluştu. Lütfen tekrar deneyin.',
        );
      }
      debugPrint('Profil paylaşma hatası: $e');
    }
  }

  Future<void> shareProfileToInstagramStory(
    BuildContext context,
    String userId,
  ) async {
    try {
      await getIt<ShareLinksService>().shareUserProfileToInstagramStory(userId);
    } catch (e) {
      if (context.mounted) {
        showErrorPopup(
          context,
          message:
              'Instagram ile paylaşılırken bir hata oluştu. Lütfen tekrar deneyin.',
        );
      }
      debugPrint('Instagram profil paylaşma hatası: $e');
    }
  }

  /// Provider'ları yeniden yükle
  void invalidateProfileData() {
    ref
      ..invalidate(profileFollowStatusProvider)
      ..invalidate(profileStatsProvider)
      ..invalidate(profileCommonFollowersProvider);
  }
}

final NotifierProviderFamily<ProfileActionNotifier, ProfileActionState, String>
profileActionProvider =
    NotifierProvider.family<ProfileActionNotifier, ProfileActionState, String>(
      ProfileActionNotifier.new,
    );
