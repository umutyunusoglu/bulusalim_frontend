import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_event_providers.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/shared/dialogs/show_multiple_events_selection_dialog.dart';
import 'package:outnest/presentation/shared/dialogs/show_no_events_dialog.dart';
import 'package:outnest/presentation/shared/navigation/dispatch_photo_intent.dart';

void navigateToCamera(BuildContext context, WidgetRef ref) {
  final ongoingEvents = ref.watch(ongoingEventsProvider).value ?? [];

  if (ongoingEvents.isEmpty) {
    showNoEventsDialog(context);
  } else if (ongoingEvents.length == 1) {
    unawaited(
      dispatchPhotoIntent(context, ongoingEvents[0], ref),
    );
  } else {
    showMultipleEventsSelectionDialog(context, ongoingEvents, ref);
  }
}
