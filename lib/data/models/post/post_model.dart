import 'package:bulusalim/core/constants/configs/app_config.dart';
import 'package:bulusalim/core/utils/types/enums/emote_enum.dart';
import 'package:bulusalim/core/utils/types/enums/feed_entity_type_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:bulusalim/domain/entities/user/compact_user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
    this.location,
    this.address,
    this.imageUrls,
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
      address: entity.address,
      hobbies: entity.hobbies,
      imageUrls: entity.imageUrls,
      participants: entity.participants,
      emoteCounts: entity.emoteCounts,

      showParticipants: entity.showParticipants,
      includeInDump: entity.includeInDump,
    );
  }

  factory PostModel.fromFirestore(Map<String, dynamic> doc) {
    late final List<String>? imageUrls;
    late final List<CompactUserEntity> participants;
    late final CompactUserEntity creator;

    imageUrls = (doc['imageUrls'] as List<dynamic>?)
        ?.map((path) => path as String)
        .toList();

    participants = (doc['participants'] as List<dynamic>)
        .map(
          (participant) => CompactUserEntity.fromMap(
            participant as Map<String, dynamic>,
          ),
        )
        .toList();
    final creatorMap = doc['creator'] as Map<String, dynamic>;

    creator = CompactUserEntity.fromMap(
      creatorMap,
    );

    final geolocation = doc['location'] as GeoPoint;
    final location = Geolocation(
      latitude: geolocation.latitude,
      longitude: geolocation.longitude,
    );

    return PostModel(
      postID: doc['postID'] as String,
      creator: creator,
      eventID: doc['eventID'] as String,
      caption: doc['caption'] as String,
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
      updatedAt: (doc['updatedAt'] as Timestamp).toDate(),
      location: location,
      address: doc['address'] as String?,
      hobbies: (doc['hobbies'] as List<dynamic>)
          .map((hobby) => HobbyEntity.fromString(hobby as String))
          .toList(),
      imageUrls: imageUrls,
      participants: participants,
      emoteCounts: (doc['emoteCounts'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          EmoteEnum.fromString(key),
          value as int,
        ),
      ),

      showParticipants: doc['showParticipants'] as bool,
      includeInDump: doc['includeInDump'] as bool,
    );
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
      address: address,
      hobbies: hobbies,
      imageUrls: imageUrls,
      participants: participants,
      emoteCounts: emoteCounts,
      showParticipants: showParticipants,
      includeInDump: includeInDump,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'postID': postID,
      'creator': creator.toMap(),
      'eventID': eventID,
      'caption': caption,
      'location': GeoPoint(
        location?.latitude ?? 0.0,
        location?.longitude ?? 0.0,
      ),
      'address': address,
      'hobbies': hobbies.map((hobby) => hobby.name).toList(),
      'imageUrls': imageUrls,
      'participants': participants
          .map((participant) => participant.toMap())
          .toList(),
      'emoteCounts': emoteCounts.map(
        (key, value) => MapEntry(key.index.toString(), value),
      ),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'showParticipants': showParticipants,
      'includeInDump': includeInDump,
      'feedType': feedType.toString(),
    };
  }

  final Identifier postID;
  final CompactUserEntity creator;
  final Identifier eventID;
  final String caption;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Geolocation? location;
  final String? address;
  final bool showParticipants;
  final bool includeInDump;
  final List<HobbyEntity> hobbies;
  final List<String>? imageUrls;
  final List<CompactUserEntity> participants;
  final Map<EmoteEnum, int> emoteCounts;
  final FeedEntityTypeEnum feedType = FeedEntityTypeEnum.post;
}
