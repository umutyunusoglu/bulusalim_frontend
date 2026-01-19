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
    required this.updatedAt,
    required this.status,
  });

  @override
  factory UserEventModel.fromEntity(UserEventEntity entity) {
    return UserEventModel(
      eventID: entity.eventId,
      role: entity.role,
      status: entity.status,
      updatedAt: entity.updatedAt,
    );
  }

  @override
  factory UserEventModel.fromFirestore(Map<String, dynamic> doc) {
    return UserEventModel(
      eventID: doc['eventID'] as Identifier,
      role: EventRoleEnum.fromString(doc['role'] as String),
      status: UserEventStatusEnum.fromString(doc['status'] as String),
      updatedAt: (doc['updatedAt'] as Timestamp).toDate(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'eventID': eventID,
      'role': role.toString(),
      'status': status.toString(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  UserEventEntity toEntity() {
    return UserEventEntity(
      eventId: eventID,
      role: role,
      status: status,
      updatedAt: updatedAt,
    );
  }

  final Identifier eventID;
  final EventRoleEnum role;
  final UserEventStatusEnum status;
  final DateTime updatedAt;
}
