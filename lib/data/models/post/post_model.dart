import 'package:bulusalim/core/constants/Configs/app_config.dart';
import 'package:bulusalim/core/utils/types/enums/emote_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PostModel extends Model<PostEntity> {
  PostModel({
    required this.postID,
    required this.userID,
    required this.eventID,
    required this.caption,
    required this.hobbies,
    required this.participants,
    required this.emoteCounts,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.imageUrls,
    this.isPinned = false,
  });

  factory PostModel.fromEntity(PostEntity entity) {
    return PostModel(
      postID: entity.postID,
      userID: entity.userID,
      eventID: entity.eventID,
      caption: entity.caption,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      location: entity.location,
      hobbies: entity.hobbies,
      imageUrls: entity.imageUrls,
      participants: entity.participants,
      emoteCounts: entity.emoteCounts,
      isPinned: entity.isPinned,
    );
  }

  factory PostModel.fromFirestore(Map<String, dynamic> doc) {
    late final List<String>? imageUrls;

    if (kDebugMode) {
      imageUrls = (doc['imageUrls'] as List<dynamic>?)
          ?.map(
            (path) => (path as String).replaceAll('localhost', AppConfig.host),
          )
          .toList();
    } else {
      imageUrls = (doc['imageUrls'] as List<dynamic>?)
          ?.map(
            (path) => path as String,
          )
          .toList();
    }

    final location = doc['location'] as GeoPoint;
    final locationMap = {
      'latitude': location.latitude,
      'longitude': location.longitude,
    };

    return PostModel(
      postID: doc['postID'] as String,
      userID: doc['userID'] as String,
      eventID: doc['eventID'] as String,
      caption: doc['caption'] as String,
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
      updatedAt: (doc['updatedAt'] as Timestamp).toDate(),
      location: Geolocation.fromMap(locationMap),
      hobbies: (doc['hobbies'] as List<dynamic>)
          .map((hobby) => HobbyEntity.fromString(hobby as String))
          .toList(),
      imageUrls: imageUrls,
      participants: (doc['participants'] as List<dynamic>)
          .map(
            (participant) => PostParticipantEntity.fromMap(
              participant as Map<String, dynamic>,
            ),
          )
          .toList(),
      emoteCounts: (doc['emoteCounts'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          EmoteEnum.values[int.parse(key)],
          value as int,
        ),
      ),
      isPinned: doc['isPinned'] as bool,
    );
  }

  @override
  PostEntity toEntity() {
    return PostEntity(
      postID: postID,
      userID: userID,
      eventID: eventID,
      caption: caption,
      createdAt: createdAt,
      updatedAt: updatedAt,
      location: location,
      hobbies: hobbies,
      imageUrls: imageUrls,
      participants: participants,
      emoteCounts: emoteCounts,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    final imageUrlsFirestore = imageUrls
        ?.map(
          (url) => url.replaceAll(
            AppConfig.host,
            'localhost',
          ),
        )
        .toList();

    return {
      'postID': postID,
      'userID': userID,
      'eventID': eventID,
      'caption': caption,
      'location': location?.toMap(),
      'hobbies': hobbies.map((hobby) => hobby.name).toList(),
      'imageUrls': imageUrlsFirestore,
      'participants': participants.map((p) => p.toMap()).toList(),
      'emoteCounts': emoteCounts.map(
        (key, value) => MapEntry(key.index.toString(), value),
      ),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isPinned': isPinned,
    };
  }

  final Identifier postID;
  final Identifier userID;
  final Identifier eventID;
  final String caption;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Geolocation? location;
  final List<HobbyEntity> hobbies;
  final List<String>? imageUrls;
  final List<PostParticipantEntity> participants;
  final Map<EmoteEnum, int> emoteCounts;
  final bool isPinned;
}
