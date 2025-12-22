import 'package:bulusalim/core/constants/configs/app_config.dart';
import 'package:bulusalim/core/utils/types/enums/event_role_enum.dart'; // EKLENDİ
import 'package:bulusalim/core/utils/types/enums/restriction_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

    // -------------------------------------------------------------
    // DÜZELTME 1: GeoPoint vs Map Kontrolü
    // -------------------------------------------------------------
    final rawLocation = doc['location'];
    double lat = 0.0;
    double lng = 0.0;

    if (rawLocation is GeoPoint) {
      // Eğer Firestore'dan GeoPoint nesnesi gelirse
      lat = rawLocation.latitude;
      lng = rawLocation.longitude;
    } else if (rawLocation is Map) {
      // Eğer Firestore'dan Map (JSON) gelirse
      lat = (rawLocation['latitude'] as num?)?.toDouble() ?? 0.0;
      lng = (rawLocation['longitude'] as num?)?.toDouble() ?? 0.0;
    }

    late final EventParticipantEntity creator;
    late final List<EventParticipantEntity> participants;

    // -------------------------------------------------------------
    // DÜZELTME 2: Creator & Participants (Eksik alanlar eklendi)
    // -------------------------------------------------------------

    // Creator verisini güvenli bir şekilde çekiyoruz
    final creatorMap = doc['creator'] as Map<String, dynamic>?;

    if (creatorMap != null) {
      // Önce normal şekilde map'ten oluşturuyoruz
      var tempCreator = EventParticipantEntity.fromMap(creatorMap);

      // Debug modundaysak localhost ayarını yapıyoruz
      if (kDebugMode) {
        tempCreator = tempCreator.copyWith(
          profileImageUrl: tempCreator.profileImageUrl.replaceAll(
            'localhost',
            AppConfig.host,
          ),
        );
      }
      creator = tempCreator;
    } else {
      // FALLBACK: Eğer creator verisi bozuksa, zorunlu alanları (role, eventScore) dolduruyoruz.
      creator = const EventParticipantEntity(
        userID: 'unknown',
        username: 'Unknown',
        profileImageUrl: '',
        role: EventRoleEnum.participant, // Zorunlu alan
        eventScore: 0.0, // Zorunlu alan
      );
    }

    // Participants listesini güvenli çekiyoruz
    participants =
        (doc['participants'] as List?)?.map((p) {
          final pMap = p as Map<String, dynamic>;
          var participant = EventParticipantEntity.fromMap(pMap);

          if (kDebugMode) {
            participant = participant.copyWith(
              profileImageUrl: participant.profileImageUrl.replaceAll(
                'localhost',
                AppConfig.host,
              ),
            );
          }
          return participant;
        }).toList() ??
        [];

    return EventModel(
      eventId: doc['eventID'] as String,
      name: doc['name'] as String,
      info: doc['info'] as String?,
      hobbies: (doc['hobbies'] as List?)?.cast<String>().toList() ?? [],
      creator: creator,
      capacity: doc['capacity'] as int,
      participants: participants,
      startTime: (doc['startTime'] as Timestamp).toDate(),
      endTime: (doc['endTime'] as Timestamp).toDate(),
      location: Geolocation.fromMap({
        'latitude': lat,
        'longitude': lng,
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
    final participantsMaps = participants
        .map(
          (p) => p
              .copyWith(
                profileImageUrl: p.profileImageUrl.replaceAll(
                  AppConfig.host,
                  'localhost',
                ),
              )
              .toMap(),
        )
        .toList();

    final creatorMap = creator.toMap();
    creatorMap['profileImageUrl'] = creator.profileImageUrl.replaceAll(
      AppConfig.host,
      'localhost',
    );

    return {
      'eventID': eventId,
      'name': name,
      'info': info,
      'hobbies': hobbies,
      'creator': creatorMap,
      'capacity': capacity,
      'participants': participantsMaps,
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
  final EventParticipantEntity creator;
  final int capacity;
  final List<EventParticipantEntity> participants;
  final DateTime startTime;
  final DateTime endTime;
  final Geolocation location;
  final EventAttributes attributes;
  final DateTime createdAt;
  final DateTime updatedAt;
}
