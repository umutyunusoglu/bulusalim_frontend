import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/shared/dialogs/show_multiple_events_selection_dialog.dart';
import 'package:outnest/presentation/shared/dialogs/show_no_events_dialog.dart';
import 'package:outnest/presentation/shared/navigation/dispatch_photo_intent.dart';

void navigateToCamera(BuildContext context) {
  // A) Kullanıcı verisini al
  final sessionService = getIt<SessionService>();
  final ongoingEvents = sessionService.currentState.ongoingEvents;

  if (ongoingEvents.isEmpty) {
    showNoEventsDialog(context);
  } else if (ongoingEvents.length == 1) {
    dispatchPhotoIntent(context, ongoingEvents[0]);
  } else {
    showMultipleEventsSelectionDialog(context, ongoingEvents);
  }
}
