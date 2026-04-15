import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_config.dart';

class NotificationTileActionExecutor {
  Future<void> execute(
    BuildContext context,
    NotificationTileActionConfig config,
  ) async {
    switch (config.type) {
      case NotificationTileActionType.navigate:
        final route = config.route;
        if (route == null || route.isEmpty) {
          _showInfoMessage(
            context,
            config.infoMessage ?? 'Aksiyon rotası bulunamadı.',
          );
          return;
        }

        if (route.startsWith('/chat/room/')) {
          final eventId = route.replaceFirst('/chat/room/', '');
          if (eventId.isEmpty) {
            _showInfoMessage(
              context,
              config.infoMessage ?? 'Sohbet için etkinlik bulunamadı.',
            );
            return;
          }

          final event = await getIt<EventRepository>().getEvent(eventId);
          if (event == null) {
            await context.push('/share/event/$eventId');
            return;
          }

          final safeCreatorImage = event.creator.profileImageUrl.isNotEmpty
              ? event.creator.profileImageUrl
              : FileService.defaultProfileImageUrl();

          await context.push(
            route,
            extra: {
              'title': event.name,
              'location': event.displayAddress,
              'participants': '${event.participants.length}/${event.capacity}',
              'startTime': event.startTime,
              'creatorID': event.creator.userID,
              'creatorProfileImage': safeCreatorImage,
              'avatars': event.participants,
              'event': event,
            },
          );
          return;
        }

        // Legacy notifications can carry malformed IDs/routes. Guard navigation.
        try {
          // If the route belongs to a bottom nav tab (ShellRoute), we MUST use .go()
          if (route.startsWith('/home') ||
              route.startsWith('/search') ||
              route.startsWith('/map') ||
              route.startsWith('/chat') ||
              route.startsWith('/my_profile')) {
            context.go(route);
          } else {
            // Root-level routes can safely be pushed
            await context.push(route);
          }
          // ignore: avoid_catching_errors
        } on AssertionError {
          if (route.startsWith('/home/profile/')) {
            context.go('/follow-requests');
            return;
          }
          _showInfoMessage(
            context,
            config.infoMessage ?? 'Bu bildirim açılamadı.',
          );
        } catch (_) {
          _showInfoMessage(
            context,
            config.infoMessage ?? 'Bu bildirim açılamadı.',
          );
        }
        return;
      case NotificationTileActionType.none:
        _showInfoMessage(
          context,
          config.infoMessage ?? 'Bu bildirim için henüz bir aksiyon yok.',
        );
        return;
    }
  }

  void _showInfoMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
