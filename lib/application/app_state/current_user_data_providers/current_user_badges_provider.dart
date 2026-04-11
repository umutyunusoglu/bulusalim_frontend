import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/service_locators/badge_repository_provider.dart';
import 'package:outnest/domain/entities/badges/badge_entity.dart';

FutureProvider<List<BadgeEntity>> currentUserBadgesProvider =
    FutureProvider.autoDispose<List<BadgeEntity>>((ref) {
      final userID = ref.watch(currentUserIDProvider);
      if (userID == null) return Future.value([]);

      final badgeRepository = ref.watch(badgeRepositoryProvider);
      return badgeRepository.getBadgesOfUser(userID);
    });
