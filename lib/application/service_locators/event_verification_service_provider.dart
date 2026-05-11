import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/data/services/event_verification_service_impl.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/services/event_verification_service.dart';

final eventVerificationServiceProvider = Provider<EventVerificationService>((
  ref,
) {
  final userId = ref.watch(currentUserIDProvider);
  return EventVerificationServiceImpl(
    currentUserId: userId,
    logger: getIt<LoggingService>(),
    eventRepository: getIt<EventRepository>(),
  );
});
