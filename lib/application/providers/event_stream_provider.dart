import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';

final StreamProviderFamily<EventEntity?, String> eventStreamProvider =
    StreamProvider.family<EventEntity?, String>((
      ref,
      eventID,
    ) {
      return getIt<EventRepository>().getEventStream(eventID);
    });
