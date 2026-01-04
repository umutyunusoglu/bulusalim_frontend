import 'package:bulusalim/core/constants/configs/app_config.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/user/compact_user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';

class EventModel extends Model<EventEntity> {
  EventModel({
    required this.eventId,
    required this.name,
    required this.searchName,
    required this.info,
    required this.hobbies,
    required this.creator,
    required this.capacity,
    required this.participantCount,
    required this.participants,
    required this.requestPool,
    required this.rejectedUsers,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    required this.isLocked,
    required this.geohash,
  });

  @override
  factory EventModel.fromEntity(EventEntity entity) {
    return EventModel(
      eventId: entity.eventID,
      name: entity.name,
      searchName: entity.name.toLowerCase(),
      info: entity.info,
      hobbies: entity.hobbies,
      creator: entity.creator,
      capacity: entity.capacity,
      participantCount: entity.participantCount,
      participants: entity.participants,
      requestPool: entity.requestPool,
      rejectedUsers: entity.rejectedUsers,
      startTime: entity.startTime,
      endTime: entity.endTime,
      location: entity.location,
      address: entity.address,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isLocked: entity.isLocked,
      geohash: entity.geohash,
    );
  }

  @override
  factory EventModel.fromFirestore(Map<String, dynamic> doc) {
    final geolocation = doc['location'] as GeoPoint;
    final location = Geolocation(
      latitude: geolocation.latitude,
      longitude: geolocation.longitude,
    );

    final geohasher = GeoHasher();
    final geohash = geohasher.encode(
      location.longitude,
      location.latitude,
      precision: 7,
    );

    final creatorMap = doc['creator'] as Map<String, dynamic>;
    final creator = EventParticipantEntity.fromMap(
      doc['creator'] as Map<String, dynamic>,
    );

    final participants = <CompactUserEntity>[];
    // Boş liste olarak başlat

    final requestPool =
        (doc['requestPool'] as List<dynamic>?)
            ?.map(
              (e) => CompactUserEntity.fromMap(e as Map<String, dynamic>),
            )
            .toList() ??
        <CompactUserEntity>[]; // Eğer null ise boş liste

    final rejectedUsers =
        (doc['rejectedUsers'] as List<dynamic>?)
            ?.map(
              (e) => CompactUserEntity.fromMap(e as Map<String, dynamic>),
            )
            .toList() ??
        <CompactUserEntity>[]; // Eğer null ise boş liste

    // Count null ise ve liste doluysa, listenin uzunluğunu alabiliriz fallback olarak
    final pCount =
        (doc['participantCount'] as int?) ??
        (participants.isNotEmpty ? participants.length : 1);

    return EventModel(
      eventId: doc['eventID'] as String,
      name: doc['name'] as String,
      searchName: (doc['name'] as String).toLowerCase(),
      info: doc['info'] as String?,
      hobbies: (doc['hobbies'] as List?)?.cast<String>().toList() ?? [],
      creator: creator,
      capacity: doc['capacity'] as int,
      // Eğer DB'de count alanı yoksa (eski veri) en az 1 (creator) varsay.
      participantCount: pCount,
      participants: participants,
      requestPool: requestPool,
      rejectedUsers: rejectedUsers,
      startTime: (doc['startTime'] as Timestamp).toDate(),
      endTime: (doc['endTime'] as Timestamp).toDate(),
      location: location,
      address: doc['address'] as String,
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
      updatedAt: (doc['updatedAt'] as Timestamp).toDate(),
      isLocked: (doc['isLocked'] as bool?) ?? false,
      geohash: geohash,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    final creatorMap = creator.toMap();
    creatorMap['profileImageUrl'] = creator.profileImageUrl;

    final participantsMaps = participants.map((p) => p.toMap()).toList();

    final requstPoolMaps = requestPool.map((p) => p.toMap()).toList();
    final rejectedUsersMaps = rejectedUsers.map((p) => p.toMap()).toList();
    return {
      'eventID': eventId,
      'name': name,
      'searchName': searchName,
      'info': info,
      'hobbies': hobbies,
      'creator': creatorMap,
      'capacity': capacity,
      'participantCount': participantCount, // Sadece sayıyı yazıyoruz
      'participants': participantsMaps, // Artık burada saklamıyoruz
      'requestPool': requstPoolMaps,
      'rejectedUsers': rejectedUsersMaps,
      'startTime': startTime,
      'endTime': endTime,
      'location': GeoPoint(
        location.latitude,
        location.longitude,
      ),
      'address': address,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isLocked': isLocked,
      'geohash': geohash,
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
      participantCount: participantCount,
      participants: participants,
      requestPool: requestPool,
      rejectedUsers: rejectedUsers,
      startTime: startTime,
      endTime: endTime,
      location: location,
      address: address,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isLocked: isLocked,
      geohash: geohash,
    );
  }

  final Identifier eventId;
  final String name;
  final String? searchName;
  final String? info;
  final List<String> hobbies;
  final EventParticipantEntity creator;
  final int capacity;
  final int participantCount;
  final List<CompactUserEntity> participants;
  final List<CompactUserEntity> requestPool;
  final List<CompactUserEntity> rejectedUsers;
  final DateTime startTime;
  final DateTime endTime;
  final Geolocation location;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocked;
  final String geohash;
}
