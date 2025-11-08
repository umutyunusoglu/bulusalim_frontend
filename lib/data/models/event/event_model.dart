import 'package:bulusalim/core/utils/types/enums/restriction_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/event/event_entity.dart';
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
    required this.participantScores,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.attributes,
    required this.metadata,
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
      participantScores: entity.participantScores,
      startTime: entity.startTime,
      endTime: entity.endTime,
      location: entity.location,
      attributes: entity.attributes,
      metadata: entity.metadata,
    );
  }

  @override
  factory EventModel.fromFirestore(Map<String, dynamic> doc) {
    final locationMap = doc['location'] as Map<String, dynamic>;
    final attributesMap = doc['attributes'] as Map<String, dynamic>;
    final metadataMap = doc['metadata'] as Map<String, dynamic>;

    return EventModel(
      eventId: doc['eventID'] as String,
      name: doc['name'] as String,
      info: doc['info'] as String?,
      hobbies: List<String>.from(doc['hobbies'] as List<dynamic>),
      creator: doc['creator'] as Identifier,
      capacity: doc['capacity'] as int,
      participants: List<Identifier>.from(doc['participants'] as List<dynamic>),
      participantScores: (doc['participantScores'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as int),
      ),
      startTime: (doc['startTime'] as Timestamp).toDate(),
      endTime: (doc['endTime'] as Timestamp).toDate(),
      location: Geolocation(
        latitude: (locationMap['latitude'] as num).toDouble(),
        longitude: (locationMap['longitude'] as num).toDouble(),
      ),
      attributes: EventAttributes(
        price: attributesMap['price'] as double,
        smoking: RestrictionEnum.values[attributesMap['smoking'] as int],
        alcohol: RestrictionEnum.values[attributesMap['alcohol'] as int],
        isPublic: attributesMap['isPublic'] as bool,
      ),
      metadata: EventMetadata(
        createdAt: (metadataMap['createdAt'] as Timestamp).toDate(),
        updatedAt: (metadataMap['updatedAt'] as Timestamp).toDate(),
      ),
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
      'participants': participants,
      'participantScores': participantScores,
      'startTime': startTime,
      'endTime': endTime,
      'location': location.toMap(),
      'attributes': attributes.toMap(),
      'metadata': metadata.toMap(),
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
      participantScores: participantScores,
      startTime: startTime,
      endTime: endTime,
      location: location,
      attributes: attributes,
      metadata: metadata,
    );
  }

  final Identifier eventId;
  final String name;
  final String? info;
  final List<String> hobbies;
  final Identifier creator;
  final int capacity;
  final List<Identifier> participants;
  final Map<Identifier, int> participantScores;
  final DateTime startTime;
  final DateTime endTime;
  final Geolocation location;
  final EventAttributes attributes;
  final EventMetadata metadata;
}
