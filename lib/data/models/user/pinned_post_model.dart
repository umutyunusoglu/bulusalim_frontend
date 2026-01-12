import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/user/compact_user_entity.dart';
import 'package:bulusalim/domain/entities/user/pinned_post_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPostModel extends Model<UserPostEntity> {
  UserPostModel({
    required this.postID,
    required this.caption,
    required this.location,
    required this.imageUrls,
    required this.participants,
    required this.emoteCounts,
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
      createdAt: entity.createdAt,
    );
  }

  factory UserPostModel.fromFirestore(Map<String, dynamic> doc) {
    final geolocation = doc['location'] as GeoPoint;
    final location = Geolocation(
      latitude: geolocation.latitude,
      longitude: geolocation.longitude,
    );

    final participants = (doc['participants'] as List<dynamic>)
        .map((e) => CompactUserEntity.fromMap(e as Map<String, dynamic>))
        .toList();

    final emoteCounts = (doc['emoteCounts'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, (value as num).toInt()),
    );

    return UserPostModel(
      postID: doc['postID'] as String? ?? '',
      caption: doc['caption'] as String? ?? '',
      location: location,
      imageUrls: (doc['imageUrls'] as List?)?.cast<String>().toList() ?? [],
      participants: participants,
      emoteCounts: emoteCounts,
      createdAt: (doc['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
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
      createdAt: createdAt,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'postID': postID,
      'caption': caption,
      'geolocation': location.toMap(),
      'imageUrls': imageUrls,
      'participants': participants.map((e) => e.toMap()).toList(),
      'emoteCounts': emoteCounts,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  final String postID;
  final String caption;
  final Geolocation location;
  final List<String> imageUrls;
  final List<CompactUserEntity> participants;
  final Map<String, int> emoteCounts;
  final DateTime createdAt;
}
