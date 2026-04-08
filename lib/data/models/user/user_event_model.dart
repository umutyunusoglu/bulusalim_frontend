import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/core/utils/types/enums/event_role_enum.dart';
import 'package:outnest/core/utils/types/enums/user_event_status_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/data/models/model.dart';
import 'package:outnest/domain/entities/user/user_event_entity.dart';

class UserEventModel extends Model<UserEventEntity> {
  @override
  factory UserEventModel.fromEntity(UserEventEntity entity) {
    return UserEventModel(
      eventID: entity.eventId,
      role: entity.role,
      status: entity.status,
      isActive: entity.isActive,
      updatedAt: entity.updatedAt,
      category: entity.category,
      isVerified: entity.isVerified,
      verifiedAt: entity.verifiedAt,
    );
  }
  @override
  factory UserEventModel.fromFirestore(Map<String, dynamic> doc) {
    return UserEventModel(
      eventID: (doc['eventID'] ?? doc['eventId'] ?? '') as String,
      role: EventRoleEnum.fromString(doc['role'] as String? ?? 'participant'),
      status: UserEventStatusEnum.fromString(
        doc['status'] as String? ?? 'upcoming',
      ),
      isActive: doc['isActive'] as bool? ?? true,
      updatedAt: (doc['updatedAt'] as Timestamp).toDate(),
      category: doc['category']?.toString(),
      isVerified: doc['isVerified'] as bool? ?? false,
      verifiedAt: doc['verifiedAt'] != null
          ? (doc['verifiedAt'] as Timestamp).toDate()
          : null,
    );
  }
  UserEventModel({
    required this.eventID,
    required this.role,
    required this.updatedAt,
    required this.isActive,
    required this.status,
    this.category,
    this.isVerified = false,
    this.verifiedAt,
  });

  final Identifier eventID;
  final EventRoleEnum role;
  final UserEventStatusEnum status;
  final bool isActive;
  final DateTime updatedAt;
  final String? category;
  final bool isVerified;
  final DateTime? verifiedAt;

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'eventID': eventID,
      'role': role.toString(),
      'status': status.toString(),
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
      'category': category,
      'isVerified': isVerified,
      // verifiedAt sadece set edilmişse yazılır, gereksiz null yazımını önler
      if (verifiedAt != null) 'verifiedAt': Timestamp.fromDate(verifiedAt!),
    };
  }

  @override
  UserEventEntity toEntity() {
    return UserEventEntity(
      eventId: eventID,
      role: role,
      status: status,
      isActive: isActive,
      updatedAt: updatedAt,
      category: category,
      isVerified: isVerified,
      verifiedAt: verifiedAt,
    );
  }
}
