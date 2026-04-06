import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/domain/entities/notification/follow_notification_entity.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/domain/repositories/inbox_repository.dart';

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  return getIt<InboxRepository>();
});

final notificationStreamProvider = StreamProvider<List<NotificationEntity>>((
  ref,
) {
  final repository = ref.watch(inboxRepositoryProvider);
  return repository.getNotificationsStream();
});

final followRequestsStreamProvider =
    StreamProvider<List<FollowNotificationEntity>>((ref) {
      final repository = ref.watch(inboxRepositoryProvider);
      return repository.getFollowRequestsStream();
    });

class UnreadFollowRequestsNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  Future<void> refresh() async {
    final repository = ref.read(inboxRepositoryProvider);
    final result = await repository.hasUnreadFollowRequest();
    state = result;
  }

  void updateState(bool newState) {
    state = newState;
  }
}

final unreadFollowRequestsProvider =
    NotifierProvider<UnreadFollowRequestsNotifier, bool>(
      UnreadFollowRequestsNotifier.new,
    );
