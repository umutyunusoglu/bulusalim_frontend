import 'package:equatable/equatable.dart';
import 'package:outnest/core/utils/types/enums/event_role_enum.dart';
import 'package:outnest/core/utils/types/enums/user_event_status_enum.dart';
import 'package:outnest/core/utils/types/types.dart';

class UserEventEntity extends Equatable {
  const UserEventEntity({
    required this.eventId,
    required this.role,
    required this.status,
    required this.isActive,
    required this.updatedAt,
    this.category,
    this.isVerified = false,
    this.verifiedAt,
  });

  final Identifier eventId;
  final EventRoleEnum role;
  final UserEventStatusEnum status;
  final bool isActive;
  final DateTime updatedAt;
  final String? category;
  final bool isVerified;
  final DateTime? verifiedAt;

  @override
  List<Object?> get props => [eventId];

  UserEventEntity copyWith({
    Identifier? eventId,
    EventRoleEnum? role,
    UserEventStatusEnum? status,
    bool? isActive,
    DateTime? updatedAt,
    String? category,
    bool? isVerified,
    DateTime? verifiedAt,
  }) {
    return UserEventEntity(
      eventId: eventId ?? this.eventId,
      role: role ?? this.role,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}
