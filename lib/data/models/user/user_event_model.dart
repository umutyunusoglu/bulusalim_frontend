import 'package:bulusalim/core/utils/types/enums/event_role_enum.dart';
import 'package:bulusalim/core/utils/types/enums/event_status_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/user/user_event_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserEventModel extends Model<UserEventEntity> {
  UserEventModel({
    required this.eventID,
    required this.eventDate,
    required this.role,
    this.status = EventStatusEnum.upcoming,
    this.pinned = false,
  });

  @override
  factory UserEventModel.fromEntity(UserEventEntity entity) {
    return UserEventModel(
      eventID: entity.eventId,
      eventDate: entity.eventDate,
      role: entity.role,
      status: entity.status,
      pinned: entity.pinned,
    );
  }

  @override
  factory UserEventModel.fromFirestore(Map<String, dynamic> doc) {
    return UserEventModel(
      eventID: doc['eventID'] as Identifier,
      eventDate: (doc['eventDate'] as Timestamp).toDate(),
      role: EventRoleEnum.values[doc['role'] as int],
      status: EventStatusEnum.fromString(doc['status'] as String),
      pinned: doc['pinned'] as bool,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'eventID': eventID,
      'eventDate': Timestamp.fromDate(eventDate),
      'role': role.index,
      'status': status.toString(),
      'pinned': pinned,
    };
  }

  @override
  UserEventEntity toEntity() {
    return UserEventEntity(
      eventId: eventID,
      eventDate: eventDate,
      role: role,
      status: status,
      pinned: pinned,
    );
  }

  final Identifier eventID;
  final DateTime eventDate;
  final EventRoleEnum role;
  final EventStatusEnum status;
  final bool pinned;
}
