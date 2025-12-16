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
    return PinnedPostModel(
      postID: doc['postID'] as String,
      caption: doc['caption'] as String,

      geolocation: Geolocation.fromMap(
        doc['location'] as Map<String, dynamic>,
      ),
      imageUrls: List<String>.from(doc['imageUrls'] as List<dynamic>),
      participants: (doc['participants'] as List<dynamic>)
          .map((e) => PostParticipantEntity.fromMap(e as Map<String, dynamic>))
          .toList(),
      emoteCounts: Map<String, int>.from(
        doc['emoteCounts'] as Map<String, dynamic>,
      ),
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
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
