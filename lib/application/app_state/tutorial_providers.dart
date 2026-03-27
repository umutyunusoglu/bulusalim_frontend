// lib/application/providers/tutorial_providers.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:outnest/application/app_state/app_initialization_state.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/services/tutorial_persistance_service.dart';

/// Returns true if the current user has already seen the tutorial.
/// Depends on isAppInitialisedProvider — only runs when session is ready.
final tutorialSeenProvider = FutureProvider<bool>((ref) async {
  final isInit = await ref.watch(isAppInitialisedProvider.future);
  if (!isInit) return false;

  final userId = getIt<SessionService>().currentUser?.userID;
  if (userId == null) return false;

  return getIt<TutorialPersistenceService>().hasSeen(userId);
});
