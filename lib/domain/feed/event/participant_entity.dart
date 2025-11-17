import 'package:bulusalim/core/utils/types/enums/event_role_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:equatable/equatable.dart';

class ParticipantEntity extends Equatable {
  const ParticipantEntity({
    required this.eventID,
    required this.userID,
    required this.role,
    required this.eventScore,
  });

  @override
  List<Object?> get props => [eventID, userID, role, eventScore];

  // For integrity IDs don't change eventID and userID
  ParticipantEntity copyWith({
    Identifier? eventID,
    Identifier? userID,
    EventRoleEnum? role,
    double? eventScore,
  }) {
    return ParticipantEntity(
      eventID: eventID ?? this.eventID,
      userID: userID ?? this.userID,
      role: role ?? this.role,
      eventScore: eventScore ?? this.eventScore,
    );
  }

  final Identifier eventID;
  final Identifier userID;
  final EventRoleEnum role;
  final double eventScore;
}
