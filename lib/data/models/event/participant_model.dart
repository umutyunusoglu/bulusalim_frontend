import 'package:bulusalim/core/utils/types/enums/event_role_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/event/participant_entity.dart';

class ParticipantModel implements Model<ParticipantEntity> {
  ParticipantModel({
    required this.eventID,
    required this.userID,
    required this.role,
    required this.eventScore,
  });

  factory ParticipantModel.fromEntity(ParticipantEntity entity) {
    return ParticipantModel(
      eventID: entity.eventID,
      userID: entity.userID,
      role: entity.role,
      eventScore: entity.eventScore,
    );
  }
  factory ParticipantModel.fromFirestore(Map<String, dynamic> firestore) {
    return ParticipantModel(
      eventID: firestore['eventID'] as Identifier,
      userID: firestore['userID'] as Identifier,
      role: EventRoleEnum.values[firestore['role'] as int],
      eventScore: (firestore['eventScore'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'eventID': eventID,
      'userID': userID,
      'role': role.index,
      'eventScore': eventScore,
    };
  }

  @override
  ParticipantEntity toEntity() {
    return ParticipantEntity(
      eventID: eventID,
      userID: userID,
      role: role,
      eventScore: eventScore,
    );
  }

  final Identifier eventID;
  final Identifier userID;
  final EventRoleEnum role;
  final double eventScore;
}
