import 'package:bulusalim/core/utils/types/enums/restriction_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/feed/event/event_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel extends Model<EventEntity> {
  EventModel({
    required this.eventId,
    required this.name,
    required this.info,
    required this.hobbies,
    required this.creator,
    required this.capacity,
    required this.participants,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.attributes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  factory EventModel.fromEntity(EventEntity entity) {
    return EventModel(
      eventId: entity.eventID,
      name: entity.name,
      info: entity.info,
      hobbies: entity.hobbies,
      creator: entity.creator,
      capacity: entity.capacity,
      participants: entity.participants,
      startTime: entity.startTime,
      endTime: entity.endTime,
      location: entity.location,
      attributes: entity.attributes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  @override
  factory EventModel.fromFirestore(Map<String, dynamic> doc) {
    final attributesMap = doc['attributes'] as Map<String, dynamic>;
    final location = doc['location'] as GeoPoint;

    return EventModel(
      eventId: doc['eventID'] as String,
      name: doc['name'] as String,
      info: doc['info'] as String?,
      hobbies: (doc['hobbies'] as List?)?.cast<String>().toList() ?? [],
      creator: doc['creator'] as Identifier,
      capacity: doc['capacity'] as int,
      participants:
          (doc['participants'] as List?)
              ?.map((p) => ParticipantEntity.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      startTime: (doc['startTime'] as Timestamp).toDate(),
      endTime: (doc['endTime'] as Timestamp).toDate(),
      location: Geolocation.fromMap({
        'latitude': location.latitude,
        'longitude': location.longitude,
      }),
      attributes: EventAttributes(
        price: (attributesMap['price'] as num?)?.toDouble() ?? 0.0,
        smoking: attributesMap['smoking'] != null
            ? RestrictionEnum.values[attributesMap['smoking'] as int]
            : RestrictionEnum.allowed,
        alcohol: attributesMap['alcohol'] != null
            ? RestrictionEnum.values[attributesMap['alcohol'] as int]
            : RestrictionEnum.allowed,
        isPublic: (attributesMap['isPublic'] as bool?) ?? true,
      ),
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
      updatedAt: (doc['updatedAt'] as Timestamp).toDate(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'eventID': eventId,
      'name': name,
      'info': info,
      'hobbies': hobbies,
      'creator': creator,
      'capacity': capacity,
      'participants': participants.map((p) => p.toMap()).toList(),
      'startTime': startTime,
      'endTime': endTime,
      'location': location.toMap(),
      'attributes': attributes.toMap(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  EventEntity toEntity() {
    return EventEntity(
      eventID: eventId,
      name: name,
      info: info,
      hobbies: hobbies,
      creator: creator,
      capacity: capacity,
      participants: participants,
      startTime: startTime,
      endTime: endTime,
      location: location,
      attributes: attributes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  final Identifier eventId;
  final String name;
  final String? info;
  final List<String> hobbies;
  final Identifier creator;
  final int capacity;
  final List<ParticipantEntity> participants;
  final DateTime startTime;
  final DateTime endTime;
  final Geolocation location;
  final EventAttributes attributes;
  final DateTime createdAt;
  final DateTime updatedAt;
}
