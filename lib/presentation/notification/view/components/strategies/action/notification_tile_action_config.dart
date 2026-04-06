enum NotificationTileActionType {
  none,
  navigate,
}

class NotificationTileActionConfig {
  const NotificationTileActionConfig({
    required this.type,
    this.route,
    this.infoMessage,
  });

  final NotificationTileActionType type;

  // Route to open when this action is a navigation action.
  final String? route;

  // Optional user-facing message when no action can be performed.
  final String? infoMessage;
}
