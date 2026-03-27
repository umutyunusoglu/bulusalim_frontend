import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/application/service_locators/event_verification_service_provider.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/event_verification_service.dart';
import 'package:outnest/presentation/shared/navigation/navigate_to_camera.dart';

Future<void> dispatchPhotoIntent(
  BuildContext context,
  EventEntity event,
  WidgetRef ref,
) async {
  final eventVerificationService = ref.watch(eventVerificationServiceProvider);

  final isEventVerified = await eventVerificationService.isEventVerified(event);

  if (isEventVerified) {
    context.go(
      '/camera',
      extra: {
        'event': event,
      },
    );
  } else {
    context.go('/home/event_verification', extra: event);
  }
}
