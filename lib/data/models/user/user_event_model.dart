import 'package:bulusalim/core/utils/types/enums/event_role_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/user/user_event_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserEventModel extends Model<UserEventEntity> {
  UserEventModel({
    required this.eventID,
    required this.eventDate,
    required this.role,
  });

  @override
  factory UserEventModel.fromEntity(UserEventEntity entity) {
    return UserEventModel(
      eventID: entity.eventId,
      eventDate: entity.eventDate,
      role: entity.role,
    );
  }

  @override
  factory UserEventModel.fromFirestore(Map<String, dynamic> doc) {
    return UserEventModel(
      eventID: doc['eventID'] as Identifier,
      eventDate: (doc['eventDate'] as Timestamp).toDate(),
      role: EventRoleEnum.values[doc['role'] as int],
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'eventID': eventID,
      'eventDate': Timestamp.fromDate(eventDate),
      'role': role.index,
    };
  }

  @override
  UserEventEntity toEntity() {
    return UserEventEntity(
      eventId: eventID,
      eventDate: eventDate,
      role: role,
    );
  }

  final Identifier eventID;
  final DateTime eventDate;
  final EventRoleEnum role;
}
