import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart'; // Import GetIt
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/emote_enum.dart';
import 'package:outnest/core/utils/types/enums/feed_entity_type_enum.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/data/models/model.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/entities/hobby/hobby_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';

class PostModel extends Model<PostEntity> {
  PostModel({
    required this.postID,
    required this.creator,
    required this.eventID,
    required this.caption,
    required this.hobbies,
    required this.participants,
    required this.emoteCounts,
    required this.createdAt,
    required this.updatedAt,
    required this.showParticipants,
    required this.includeInDump,
    required this.imageUrls,
    required this.isPinned,
    this.location,
    this.address,
  });

  factory PostModel.fromEntity(PostEntity entity) {
    return PostModel(
      postID: entity.postID,
      creator: entity.creator,
      eventID: entity.eventID,
      caption: entity.caption,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      location: entity.location,
      address: entity.displayAddress,
      hobbies: entity.hobbies,
      imageUrls: entity.imageUrls,
      participants: entity.participants,
      emoteCounts: entity.emoteCounts,
      showParticipants: entity.showParticipants,
      includeInDump: entity.includeInDump,
      isPinned: entity.isPinned,
    );
  }

  factory PostModel.fromFirestore(Map<String, dynamic> doc) {
    final logger = getIt<LoggingService>();

    try {
      // 1. Safe Image URLs Parsing
      final parsedImageUrls =
          (doc['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      // 2. Safe Participants Parsing
      var parsedParticipants = <CompactUserEntity>[];
      if (doc['participants'] != null && doc['participants'] is List) {
        try {
          parsedParticipants = List<dynamic>.from(doc['participants'] as List)
              .map((p) {
                final map = Map<String, dynamic>.from(p as Map);
                return CompactUserEntity.fromMap(map);
              })
              .toList();
        } catch (e) {
          logger.warn(
            'PostModel: Error parsing participants list. Defaulting to empty: $e',
          );
        }
      }

      // 3. Safe Creator Parsing [DÜZELTİLEN KISIM]
      CompactUserEntity parsedCreator;
      try {
        final rawCreator = doc['creator'];
        if (rawCreator != null && rawCreator is Map) {
          // Gelen veriyi kopyala (Mutable hale getir)
          final creatorMap = Map<String, dynamic>.from(rawCreator);

          // EĞER UNIVERSITY YOKSA BOŞ EKLE
          // Bu sayede CompactUserEntity.fromMap içinde "university" aradığında null almaz.
          if (!creatorMap.containsKey('university') ||
              creatorMap['university'] == null) {
            creatorMap['university'] = '';
          }

          // Diğer kritik alanlar için de aynısını yapabilirsin
          if (!creatorMap.containsKey('displayName')) {
            creatorMap['displayName'] = 'Unknown';
          }
          if (!creatorMap.containsKey('username')) {
            creatorMap['username'] = 'unknown';
          }

          parsedCreator = CompactUserEntity.fromMap(creatorMap);
        } else {
          throw Exception('Creator data is null/invalid');
        }
      } catch (e) {
        // ... Fallback logic ...
        // Fallback kullanıcında da university'i boş ver
        parsedCreator = CompactUserEntity.fromMap(const {
          'userID': 'unknown',
          'username': 'Unknown',
          'university': '',
          'profileImageUrl': '',
        });
      }

      // 4. Safe Location Parsing
      Geolocation? parsedLocation;
      if (doc['location'] != null && doc['location'] is GeoPoint) {
        final geoPoint = doc['location'] as GeoPoint;
        parsedLocation = Geolocation(
          latitude: geoPoint.latitude,
          longitude: geoPoint.longitude,
        );
      }

      // 5. Safe Hobbies Parsing
      var parsedHobbies = <HobbyEntity>[];
      if (doc['hobbies'] != null && doc['hobbies'] is List) {
        try {
          parsedHobbies = List<dynamic>.from(
            doc['hobbies'] as List,
          ).map((h) => HobbyEntity.fromString(h.toString())).toList();
        } catch (e) {
          logger.warn('PostModel: Error parsing hobbies.');
        }
      }

      // 6. Safe Emote Counts Parsing
      var parsedEmoteCounts = <EmoteEnum, int>{};
      if (doc['emoteCounts'] != null && doc['emoteCounts'] is Map) {
        try {
          final rawEmotes = Map<String, dynamic>.from(
            doc['emoteCounts'] as Map,
          );
          parsedEmoteCounts = rawEmotes.map(
            (key, value) => MapEntry(
              EmoteEnum.fromString(key),
              (value as num?)?.toInt() ?? 0,
            ),
          );
        } catch (e) {
          logger.warn('PostModel: Error parsing emoteCounts.');
        }
      }

      // 7. Safe Date Parsing
      var parsedCreatedAt = DateTime.now();
      var parsedUpdatedAt = DateTime.now();
      try {
        if (doc['createdAt'] is Timestamp) {
          parsedCreatedAt = (doc['createdAt'] as Timestamp).toDate();
        }
        if (doc['updatedAt'] is Timestamp) {
          parsedUpdatedAt = (doc['updatedAt'] as Timestamp).toDate();
        }
      } catch (e) {
        logger.warn('PostModel: Error parsing timestamps.');
      }

      return PostModel(
        postID: doc['postID']?.toString() ?? '',
        creator: parsedCreator,
        eventID: doc['eventID']?.toString() ?? '',
        caption: doc['caption']?.toString() ?? '',
        createdAt: parsedCreatedAt,
        updatedAt: parsedUpdatedAt,
        location: parsedLocation,
        address: doc['address']?.toString(),
        hobbies: parsedHobbies,
        imageUrls: parsedImageUrls,
        participants: parsedParticipants,
        emoteCounts: parsedEmoteCounts,
        showParticipants: doc['showParticipants'] as bool? ?? true,
        includeInDump: doc['includeInDump'] as bool? ?? false,
        isPinned: doc['isPinned'] as bool? ?? false,
      );
    } catch (e) {
      // Burası sadece en kötü senaryoda (PostModel'in kendisi oluşamazsa) çalışır.
      logger.error(
        'PostModel: Critical failure in fromFirestore factory. error: $e',
      );
      rethrow;
    }
  }

  @override
  PostEntity toEntity() {
    return PostEntity(
      postID: postID,
      creator: creator,
      eventID: eventID,
      caption: caption,
      createdAt: createdAt,
      updatedAt: updatedAt,
      location: location,
      displayAddress: address,
      hobbies: hobbies,
      imageUrls: imageUrls,
      participants: participants,
      emoteCounts: emoteCounts,
      showParticipants: showParticipants,
      includeInDump: includeInDump,
      isPinned: isPinned,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'postID': postID,
      'creator': creator.toMap(),
      'eventID': eventID,
      'caption': caption,
      'location': location != null
          ? GeoPoint(location!.latitude, location!.longitude)
          : null,
      'address': address,
      'hobbies': hobbies.map((hobby) => hobby.name).toList(),
      'imageUrls': imageUrls ?? [],
      'participants': participants.map((p) => p.toMap()).toList(),
      'emoteCounts': emoteCounts.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'showParticipants': showParticipants,
      'includeInDump': includeInDump,
      'isPinned': isPinned,
      'feedType': feedType.toString(),
    };
  }

  final Identifier postID;
  final CompactUserEntity creator;
  final Identifier eventID;
  final String caption;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Geolocation? location;
  final String? address;
  final bool showParticipants;
  final bool includeInDump;
  final List<HobbyEntity> hobbies;
  final List<String> imageUrls;
  final List<CompactUserEntity> participants;
  final Map<EmoteEnum, int> emoteCounts;
  final bool isPinned;
  final FeedEntityTypeEnum feedType = FeedEntityTypeEnum.post;
}
