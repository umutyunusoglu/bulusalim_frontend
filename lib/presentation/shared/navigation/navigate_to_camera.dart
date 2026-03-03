import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/shared/dialogs/show_multiple_events_selection_dialog.dart';
import 'package:outnest/presentation/shared/dialogs/show_no_events_dialog.dart';

void navigateToCamera(BuildContext context) {
  // A) Kullanıcı verisini al
  final sessionService = getIt<SessionService>();
  final ongoingEvents = sessionService.currentState.ongoingEvents;

  if (ongoingEvents.isEmpty) {
    showNoEventsDialog(context);
  } else if (ongoingEvents.length == 1) {
    context.push('/camera', extra: {'event': ongoingEvents.first});
  } else {
    showMultipleEventsSelectionDialog(context, ongoingEvents);
  }
}
