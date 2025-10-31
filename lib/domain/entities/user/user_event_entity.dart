import 'package:bulusalim/core/utils/types/enums/event_role_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:equatable/equatable.dart';

class UserEventEntity extends Equatable {
  const UserEventEntity({
    required this.eventId,
    required this.eventDate,
    required this.role,
  });

  @override
  List<Object?> get props => [
    eventId,
    eventDate,
    role,
  ];

  UserEventEntity copyWith({
    Identifier? eventId,
    DateTime? eventDate,
    EventRoleEnum? role,
  }) {
    return UserEventEntity(
      eventId: eventId ?? this.eventId,
      eventDate: eventDate ?? this.eventDate,
      role: role ?? this.role,
    );
  }

  final Identifier eventId;
  final DateTime eventDate;
  final EventRoleEnum role;
}
