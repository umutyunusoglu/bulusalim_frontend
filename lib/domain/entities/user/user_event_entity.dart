import 'package:bulusalim/core/utils/types/enums/event_role_enum.dart';
import 'package:bulusalim/core/utils/types/enums/event_status_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:equatable/equatable.dart';

class UserEventEntity extends Equatable {
  UserEventEntity({
    required this.eventId,
    required this.eventDate,
    required this.role,
    required this.status,
    required this.pinned,
  }) {
    if ((status == EventStatusEnum.completed ||
            status == EventStatusEnum.cancelled) &&
        pinned) {
      throw ArgumentError('Completed events cannot be pinned.');
    }
  }

  @override
  List<Object?> get props => [
    eventId,
    eventDate,
    role,
    status,
    pinned,
  ];

  UserEventEntity copyWith({
    Identifier? eventId,
    DateTime? eventDate,
    EventRoleEnum? role,
    EventStatusEnum? status,
    bool? pinned,
  }) {
    return UserEventEntity(
      eventId: eventId ?? this.eventId,
      eventDate: eventDate ?? this.eventDate,
      role: role ?? this.role,
      status: status ?? this.status,
      pinned: pinned ?? this.pinned,
    );
  }

  final Identifier eventId;
  final DateTime eventDate;
  final EventRoleEnum role;
  final EventStatusEnum status;
  final bool pinned;
}
