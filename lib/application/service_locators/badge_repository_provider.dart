import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/service_locators/logging_service_provider.dart';
import 'package:outnest/data/repositories/badge_repository_impl.dart';
import 'package:outnest/domain/repositories/badge_repository.dart';

Provider<BadgeRepository> badgeRepositoryProvider = Provider<BadgeRepository>((
  ref,
) {
  return BadgeRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    logger: ref.watch(loggingServiceProvider),
  );
});
