import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/event_status_enum.dart';
import 'package:outnest/core/utils/types/enums/visibility_enum.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/data/models/model.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';

class EventModel extends Model<EventEntity> {
  EventModel({
    required this.eventId,
    required this.name,
    required this.searchName,
    required this.hobbies,
    required this.creator,
    required this.capacity,
    required this.status,
    required this.participantCount,
    required this.participants,
    required this.requestPool,
    required this.rejectedUsers,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.displayAddress,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    required this.isLocked,
    required this.geohash,
    required this.visibility,
    required this.showOnMap,
    this.visibilityGroupID,
    this.communityDescription,
    this.communityRules,
    this.communityVenueInfo,
    this.communityLink,
    this.communityMaxParticipants,
    this.communityRequiresDocument,
    this.communityCoverImageUrl,
  });

  @override
  factory EventModel.fromEntity(EventEntity entity) {
    return EventModel(
      eventId: entity.eventID,
      name: entity.name,
      searchName: entity.name.toLowerCase(),
      status: entity.status,
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
      displayAddress: entity.displayAddress,
      address: entity.address,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isLocked: entity.isLocked,
      geohash: entity.geohash,
      visibility: entity.visibility,
      visibilityGroupID: entity.visibilityGroupID,
      showOnMap: entity.showOnMap,
      communityDescription: entity.communityDescription,
      communityRules: entity.communityRules,
      communityVenueInfo: entity.communityVenueInfo,
      communityLink: entity.communityLink,
      communityMaxParticipants: entity.communityMaxParticipants,
      communityRequiresDocument: entity.communityRequiresDocument,
      communityCoverImageUrl: entity.communityCoverImageUrl,
    );
  }

  @override
  factory EventModel.fromFirestore(Map<String, dynamic> doc) {
    Geolocation? location;
    String? geohash = doc['geohash'] as String?;

    if (doc['location'] != null) {
      final geolocation = doc['location'] as GeoPoint;
      location = Geolocation(
        latitude: geolocation.latitude,
        longitude: geolocation.longitude,
      );

      // Eğer geohash yoksa ama location varsa hesapla (Fallback)
      if (geohash == null) {
        final geohasher = GeoHasher();
        geohash = geohasher.encode(
          location.longitude,
          location.latitude,
          precision: 7,
        );
      }
    }

    // 2. Address kontrolü
    final String? address = doc['address'] as String?;

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

    VisibilityEnum visibility;
    try {
      visibility = VisibilityEnum.fromString(doc['visibility'] as String);
    } catch (e) {
      getIt<LoggingService>().warn(
        'VisibilityEnum parsing failed, defaulting to everyone. Error: $e',
      );
      visibility = VisibilityEnum.everyone;
    }

    return EventModel(
      eventId: doc['eventID'] as String,
      name: doc['name'] as String,
      searchName: (doc['name'] as String).toLowerCase(),
      hobbies: (doc['hobbies'] as List?)?.cast<String>().toList() ?? [],
      creator: creator,
      capacity: doc['capacity'] as int,
      status: EventStatusEnum.fromString(doc['status'] as String),
      participantCount: pCount,
      participants: participants,
      requestPool: requestPool,
      rejectedUsers: rejectedUsers,
      startTime: (doc['startTime'] as Timestamp).toDate(),
      endTime: (doc['endTime'] as Timestamp?)?.toDate(),
      location: location,
      displayAddress: doc['displayAddress'] as String,
      address: address,
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
      updatedAt: (doc['updatedAt'] as Timestamp).toDate(),
      isLocked: (doc['isLocked'] as bool?) ?? false,
      geohash: geohash ?? '',
      visibility: visibility,
      visibilityGroupID: doc['visibilityGroupID'] as String?,
      showOnMap: (doc['showOnMap'] as bool?) ?? false,
      communityDescription: doc['communityDescription'] as String?,
      communityRules: doc['communityRules'] as String?,
      communityVenueInfo: doc['communityVenueInfo'] as String?,
      communityLink: doc['communityLink'] as String?,
      communityMaxParticipants: doc['communityMaxParticipants'] as int?,
      communityRequiresDocument: doc['communityRequiresDocument'] as bool?,
      communityCoverImageUrl: doc['communityCoverImageUrl'] as String?,
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
      'hobbies': hobbies,
      'creator': creatorMap,
      'capacity': capacity,
      'status': status.toString(),
      'participantCount': participantCount, // Sadece sayıyı yazıyoruz
      'participants': participantsMaps, // Artık burada saklamıyoruz
      'requestPool': requstPoolMaps,
      'rejectedUsers': rejectedUsersMaps,
      'startTime': startTime,
      'endTime': endTime,
      'displayAddress': displayAddress,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isLocked': isLocked,
      'geohash': geohash,
      'feedType': 'event',
      'visibility': visibility.toString(),
      'visibilityGroupID': visibilityGroupID,
      'showOnMap': showOnMap,
      'communityDescription': communityDescription,
      'communityRules': communityRules,
      'communityVenueInfo': communityVenueInfo,
      'communityLink': communityLink,
      'communityMaxParticipants': communityMaxParticipants,
      'communityRequiresDocument': communityRequiresDocument,
      'communityCoverImageUrl': communityCoverImageUrl,
    };
  }

  Map<String, dynamic> toPrivateFirestore() {
    return {
      'address': address,
      'location': location != null
          ? GeoPoint(location!.latitude, location!.longitude)
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  EventEntity toEntity() {
    return EventEntity(
      eventID: eventId,
      name: name,
      hobbies: hobbies,
      creator: creator,
      capacity: capacity,
      participantCount: participantCount,
      status: status,
      participants: participants,
      requestPool: requestPool,
      rejectedUsers: rejectedUsers,
      startTime: startTime,
      endTime: endTime,
      location: location,
      displayAddress: displayAddress,
      address: address,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isLocked: isLocked,
      geohash: geohash,
      visibility: visibility,
      visibilityGroupID: visibilityGroupID,
      showOnMap: showOnMap,
      communityDescription: communityDescription,
      communityRules: communityRules,
      communityVenueInfo: communityVenueInfo,
      communityLink: communityLink,
      communityMaxParticipants: communityMaxParticipants,
      communityRequiresDocument: communityRequiresDocument,
      communityCoverImageUrl: communityCoverImageUrl,
    );
  }

  static Map<String, dynamic> parseSensitiveData(Map<String, dynamic> doc) {
    Geolocation? realLocation;
    if (doc['realLocation'] != null) {
      final geo = doc['realLocation'] as GeoPoint;
      realLocation = Geolocation(
        latitude: geo.latitude,
        longitude: geo.longitude,
      );
    }

    return {
      'address': doc['realAddress'] as String?,
      'location': realLocation,
    };
  }

  Map<String, dynamic> toSensitiveFirestore() {
    return {
      'realAddress': address, // Entity'deki gerçek adres
      'realLocation': location != null
          ? GeoPoint(location!.latitude, location!.longitude)
          : null, // Entity'deki gerçek konum
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  final Identifier eventId;
  final String name;
  final String? searchName;
  final List<String> hobbies;
  final EventStatusEnum status;
  final EventParticipantEntity creator;
  final int capacity;
  final int participantCount;
  final List<CompactUserEntity> participants;
  final List<CompactUserEntity> requestPool;
  final List<CompactUserEntity> rejectedUsers;
  final DateTime startTime;
  final DateTime? endTime;
  final Geolocation? location;
  final String displayAddress;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocked;
  final VisibilityEnum visibility;
  final String? visibilityGroupID;
  final String geohash;
  final bool showOnMap;
  final String? communityDescription;
  final String? communityRules;
  final String? communityVenueInfo;
  final String? communityLink;
  final int? communityMaxParticipants;
  final bool? communityRequiresDocument;
  final String? communityCoverImageUrl;
}
