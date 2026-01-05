import 'package:bulusalim/core/utils/types/enums/event_role_enum.dart';
import 'package:bulusalim/core/utils/types/enums/user_event_status_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/user/user_event_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserEventModel extends Model<UserEventEntity> {
  UserEventModel({
    required this.eventID,
    required this.role,
    this.status = UserEventStatusEnum.upcoming,
  });

  @override
  factory UserEventModel.fromEntity(UserEventEntity entity) {
    return UserEventModel(
      eventID: entity.eventId,
      role: entity.role,
      status: entity.status,
    );
  }

  @override
  factory UserEventModel.fromFirestore(Map<String, dynamic> doc) {
    return UserEventModel(
      eventID: doc['eventID'] as Identifier,
      role: EventRoleEnum.participant, //TODO

      status: UserEventStatusEnum.fromString(doc['status'] as String),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'eventID': eventID,
      'role': role.index,
      'status': status.toString(),
    };
  }

  @override
  UserEventEntity toEntity() {
    return UserEventEntity(
      eventId: eventID,
      role: role,
      status: status,
    );
  }

  final Identifier eventID;
  final EventRoleEnum role;
  final UserEventStatusEnum status;
}
