import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
import 'package:bulusalim/domain/entities/user/pinned_post_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PinnedPostModel extends Model<PinnedPostEntity> {
  PinnedPostModel({
    required this.postID,
    required this.caption,
    required this.geolocation,
    required this.imageUrls,
    required this.participants,
    required this.emoteCounts,
    required this.createdAt,
  });

  factory PinnedPostModel.fromEntity(PinnedPostEntity entity) {
    return PinnedPostModel(
      postID: entity.postID,
      caption: entity.caption,
      geolocation: entity.geolocation,
      imageUrls: entity.imageUrls,
      participants: entity.participants,
      emoteCounts: entity.emoteCounts,
      createdAt: entity.createdAt,
    );
  }

  factory PinnedPostModel.fromFirestore(Map<String, dynamic> doc) {
    // 1. Geolocation Güvenli Çeviri
    Geolocation safeGeolocation;
    final rawGeo = doc['geolocation'];

    if (rawGeo is Map<String, dynamic>) {
      safeGeolocation = Geolocation.fromMap(rawGeo);
    } else if (rawGeo is GeoPoint) {
      safeGeolocation = Geolocation(
        latitude: rawGeo.latitude,
        longitude: rawGeo.longitude,
      );
    } else {
      // DÜZELTME 1: 'const' kaldırıldı. Geolocation sınıfı const desteklemiyor olabilir.
      safeGeolocation = Geolocation(latitude: 0, longitude: 0);
    }

    // 2. Participants Güvenli Çeviri
    List<PostParticipantEntity> safeParticipants = [];
    if (doc['participants'] != null && doc['participants'] is List) {
      safeParticipants = (doc['participants'] as List)
          .map((e) => PostParticipantEntity.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    // 3. EmoteCounts Güvenli Çeviri
    Map<String, int> safeEmoteCounts = {};
    if (doc['emoteCounts'] != null && doc['emoteCounts'] is Map) {
      // DÜZELTME 2: 'as Map' eklendi ve güvenli dönüşüm sağlandı.
      safeEmoteCounts = Map<String, int>.from(doc['emoteCounts'] as Map);
    }

    return PinnedPostModel(
      postID: doc['postID'] as String? ?? '',
      caption: doc['caption'] as String? ?? '',
      geolocation: safeGeolocation,
      imageUrls: (doc['imageUrls'] as List?)?.cast<String>().toList() ?? [],
      participants: safeParticipants,
      emoteCounts: safeEmoteCounts,
      createdAt: (doc['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  PinnedPostEntity toEntity() {
    return PinnedPostEntity(
      postID: postID,
      caption: caption,
      geolocation: geolocation,
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
      'geolocation': geolocation.toMap(),
      'imageUrls': imageUrls,
      'participants': participants.map((e) => e.toMap()).toList(),
      'emoteCounts': emoteCounts,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  final String postID;
  final String caption;
  final Geolocation geolocation;
  final List<String> imageUrls;
  final List<PostParticipantEntity> participants;
  final Map<String, int> emoteCounts;
  final DateTime createdAt;
}
