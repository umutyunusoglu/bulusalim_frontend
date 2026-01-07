import 'package:bulusalim/core/utils/types/enums/event_role_enum.dart';
import 'package:bulusalim/core/utils/types/enums/user_event_status_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:equatable/equatable.dart';

class UserEventEntity extends Equatable {
  const UserEventEntity({
    required this.eventId,
    required this.role,
    required this.status,
  });

  @override
  List<Object?> get props => [
    eventId,
  ];

  UserEventEntity copyWith({
    Identifier? eventId,
    EventRoleEnum? role,
    UserEventStatusEnum? status,
  }) {
    return UserEventEntity(
      eventId: eventId ?? this.eventId,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }

  final Identifier eventId;
  final EventRoleEnum role;
  final UserEventStatusEnum status;
}
