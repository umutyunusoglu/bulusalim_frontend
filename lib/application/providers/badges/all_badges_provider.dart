import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/application/service_locators/badge_repository_provider.dart';
import 'package:outnest/domain/entities/badges/badge_entity.dart';
import 'package:outnest/domain/repositories/badge_repository.dart';

FutureProvider<List<BadgeEntity>> allBadgesProvider =
    FutureProvider<List<BadgeEntity>>((
      ref,
    ) {
      return ref.watch(badgeRepositoryProvider).getAllBadges();
    });
