import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/service_locators/badge_repository_provider.dart';
import 'package:outnest/domain/entities/badges/badge_entity.dart';

FutureProvider<List<BadgeEntity>> allBadgesProvider =
    FutureProvider<List<BadgeEntity>>((
      ref,
    ) {
      return ref.watch(badgeRepositoryProvider).getAllBadges();
    });
