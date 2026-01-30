import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/data/models/model.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/pinned_post_entity.dart';

final getIt = GetIt.instance;

class UserPostModel extends Model<UserPostEntity> {
  UserPostModel({
    required this.postID,
    required this.caption,
    required this.location,
    required this.imageUrls,
    required this.participants,
    required this.emoteCounts,
    required this.isPinned,
    required this.createdAt,
  });

  factory UserPostModel.fromEntity(UserPostEntity entity) {
    return UserPostModel(
      postID: entity.postID,
      caption: entity.caption,
      location: entity.location,
      imageUrls: entity.imageUrls,
      participants: entity.participants,
      emoteCounts: entity.emoteCounts,
      isPinned: entity.isPinned,
      createdAt: entity.createdAt,
    );
  }

  factory UserPostModel.fromFirestore(Map<String, dynamic> doc) {
    final logger = getIt<LoggingService>();

    try {
      // 1. Safe Location Parsing
      Geolocation parsedLocation = Geolocation(latitude: 0, longitude: 0);
      if (doc['location'] != null && doc['location'] is GeoPoint) {
        try {
          final geoPoint = doc['location'] as GeoPoint;
          parsedLocation = Geolocation(
            latitude: geoPoint.latitude,
            longitude: geoPoint.longitude,
          );
        } catch (e) {
          logger.warn(
            'UserPostModel: Error parsing GeoPoint. Defaulting to (0,0).',
          );
        }
      }

      // 2. Safe Participants Parsing
      List<CompactUserEntity> parsedParticipants = [];
      if (doc['participants'] != null && doc['participants'] is List) {
        try {
          parsedParticipants = (doc['participants'] as List).map((e) {
            return CompactUserEntity.fromMap(e as Map<String, dynamic>);
          }).toList();
        } catch (e) {
          logger.warn(
            'UserPostModel: Error parsing participants. Defaulting to [].',
          );
        }
      }

      // 3. Safe EmoteCounts Parsing
      Map<String, int> parsedEmoteCounts = {};
      if (doc['emoteCounts'] != null && doc['emoteCounts'] is Map) {
        try {
          final rawMap = doc['emoteCounts'] as Map<String, dynamic>;
          parsedEmoteCounts = rawMap.map(
            (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
          );
        } catch (e) {
          logger.warn(
            'UserPostModel: Error parsing emoteCounts. Defaulting to {}.',
          );
        }
      }

      // 4. Safe Image URLs Parsing
      List<String> parsedImageUrls = [];
      if (doc['imageUrls'] != null && doc['imageUrls'] is List) {
        parsedImageUrls = (doc['imageUrls'] as List)
            .map((e) => e.toString())
            .toList();
      }

      // 5. Safe Date Parsing
      DateTime parsedCreatedAt = DateTime.now();
      if (doc['createdAt'] is Timestamp) {
        parsedCreatedAt = (doc['createdAt'] as Timestamp).toDate();
      }

      return UserPostModel(
        postID: doc['postID']?.toString() ?? '',
        caption: doc['caption']?.toString() ?? '',
        location: parsedLocation,
        imageUrls: parsedImageUrls,
        participants: parsedParticipants,
        emoteCounts: parsedEmoteCounts,
        isPinned: doc['isPinned'] as bool? ?? false,
        createdAt: parsedCreatedAt,
      );
    } catch (e) {
      logger.error(
        'UserPostModel: Critical failure in fromFirestore factory.',
      );
      // Depending on your app flow, you might want to return a dummy object or rethrow.
      rethrow;
    }
  }

  @override
  UserPostEntity toEntity() {
    return UserPostEntity(
      postID: postID,
      caption: caption,
      location: location,
      imageUrls: imageUrls,
      participants: participants,
      emoteCounts: emoteCounts,
      isPinned: isPinned,
      createdAt: createdAt,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'postID': postID,
      'caption': caption,
      // Fixed: Converted back to GeoPoint to match fromFirestore expectation
      'location': GeoPoint(location.latitude, location.longitude),
      'imageUrls': imageUrls,
      'participants': participants.map((e) => e.toMap()).toList(),
      'emoteCounts': emoteCounts,
      'isPinned': isPinned,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  final String postID;
  final String caption;
  final Geolocation location;
  final List<String> imageUrls;
  final List<CompactUserEntity> participants;
  final Map<String, int> emoteCounts;
  final bool isPinned;
  final DateTime createdAt;
}
