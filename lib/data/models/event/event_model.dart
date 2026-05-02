import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/core/utils/types/enums/event_status_enum.dart';
import 'package:outnest/core/utils/types/enums/visibility_enum.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/data/models/model.dart';
import 'package:outnest/domain/entities/feed/event/event_community_data.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';

class EventModel extends Model<EventEntity> {
  EventModel({
    required this.eventId,
    required this.name,
    required this.city,
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
    required this.accountType,
    this.visibilityGroupID,
    this.communityData,
  });

  @override
  factory EventModel.fromEntity(EventEntity entity) {
    return EventModel(
      eventId: entity.eventID,
      name: entity.name,
      city: entity.city,
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
      accountType: entity.accountType,
      communityData: entity.communityData,
    );
  }

  @override
  factory EventModel.fromFirestore(Map<String, dynamic> doc) {
    Geolocation? location;
    var geohash = doc['geohash'] as String?;

    if (doc['location'] != null) {
      final geolocation = doc['location'] as GeoPoint;
      location = Geolocation(
        latitude: geolocation.latitude,
        longitude: geolocation.longitude,
      );

      if (geohash == null) {
        final geohasher = GeoHasher();
        geohash = geohasher.encode(
          location.longitude,
          location.latitude,
          precision: 7,
        );
      }
    }

    final String? address = doc['address'] as String?;

    final creator = EventParticipantEntity.fromMap(
      doc['creator'] as Map<String, dynamic>,
    );

    final participants = <CompactUserEntity>[];

    final requestPool =
        (doc['requestPool'] as List<dynamic>?)
            ?.map(
              (e) => CompactUserEntity.fromMap(e as Map<String, dynamic>),
            )
            .toList() ??
        <CompactUserEntity>[];

    final rejectedUsers =
        (doc['rejectedUsers'] as List<dynamic>?)
            ?.map(
              (e) => CompactUserEntity.fromMap(e as Map<String, dynamic>),
            )
            .toList() ??
        <CompactUserEntity>[];

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

    // AccountType: Firebase'den oku, yoksa personal
    final accountType = AccountType.fromString(
      doc['accountType'] as String? ?? 'personal',
    );

    // Community data: varsa parse et
    final communityData = EventCommunityData.fromMap(doc);
    // Tüm alanlar null ise communityData'yı null yap
    final hasAnyCommunityField =
        communityData.description != null ||
        communityData.rules != null ||
        communityData.venueInfo != null ||
        communityData.link != null ||
        communityData.maxParticipants != null ||
        communityData.requiresDocument != null ||
        communityData.coverImageUrl != null;

    return EventModel(
      eventId: doc['eventID'] as String,
      name: doc['name'] as String,
      city: doc['city'] as String?,
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
      accountType: accountType,
      communityData: hasAnyCommunityField ? communityData : null,
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
      'city': city,
      'searchName': searchName,
      'hobbies': hobbies,
      'creator': creatorMap,
      'capacity': capacity,
      'status': status.toString(),
      'participantCount': participantCount,
      'participants': participantsMaps,
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
      'accountType': accountType.toString(),
      // Community alanlarını flat olarak yaz (Firebase yapısını bozmamak için)
      if (communityData != null) ...communityData!.toMap(),
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
      city: city,
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
      accountType: accountType,
      communityData: communityData,
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
      'realAddress': address,
      'realLocation': location != null
          ? GeoPoint(location!.latitude, location!.longitude)
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  final Identifier eventId;
  final String name;
  final String? city;
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
  final AccountType accountType;
  final EventCommunityData? communityData;
}
