import 'package:bulusalim/core/utils/types/enums/emote_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:bulusalim/domain/entities/post/post_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel extends Model<PostEntity> {
  PostModel({
    required this.postID,
    required this.userID,
    required this.eventID,
    required this.title,
    required this.metadata,
    required this.hobbies,
    required this.participants,
    required this.emoteCounts,
    this.location,
    this.photoUrls,
  });

  factory PostModel.fromEntity(PostEntity entity) {
    return PostModel(
      postID: entity.postID,
      userID: entity.userID,
      eventID: entity.eventID,
      title: entity.title,
      metadata: entity.metadata,
      location: entity.location,
      hobbies: entity.hobbies,
      photoUrls: entity.photoUrls,
      participants: entity.participants,
      emoteCounts: entity.emoteCounts,
    );
  }

  factory PostModel.fromFirestore(Map<String, dynamic> doc) {
    final location = doc['location'] as GeoPoint;
    final locationMap = {
      "latitude": location.latitude,
      "longitude": location.longitude,
    };
    return PostModel(
      postID: doc['postId'] as String,
      userID: doc['userId'] as String,
      eventID: doc['eventId'] as String,
      title: doc['title'] as String,
      metadata: PostMetadata(
        createdAt: DateTime(2003),
        updatedAt: DateTime(2000),
      ), //TODO
      location: Geolocation.fromMap(locationMap),
      hobbies: (doc['hobbies'] as List<dynamic>)
          .map((hobby) => HobbyEntity.fromString(hobby as String))
          .toList(),
      photoUrls: (doc['photoUrls'] as List<dynamic>?)
          ?.map((url) => url as String)
          .toList(),
      participants: List<Identifier>.from(doc['participants'] as List<dynamic>),
      emoteCounts: (doc['emoteCounts'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          EmoteEnum.values[int.parse(key)],
          value as int,
        ),
      ),
    );
  }

  @override
  PostEntity toEntity() {
    return PostEntity(
      postID: postID,
      userID: userID,
      eventID: eventID,
      title: title,
      metadata: metadata,
      location: location, //TODO
      hobbies: hobbies,
      photoUrls: photoUrls,
      participants: participants,
      emoteCounts: emoteCounts,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'postID': postID,
      'userID': userID,
      'eventID': eventID,
      'title': title,
      'metadata': metadata.toMap(),
      'location': location?.toMap(),
      'hobbies': hobbies.map((hobby) => hobby.name).toList(),
      'photoUrls': photoUrls,
      'participants': participants,
      'emoteCounts': emoteCounts.map(
        (key, value) => MapEntry(key.index.toString(), value),
      ),
    };
  }

  final Identifier postID;
  final Identifier userID;
  final Identifier eventID;
  final String title;
  final PostMetadata metadata;
  final Geolocation? location;
  final List<HobbyEntity> hobbies;
  final List<String>? photoUrls;
  final List<Identifier> participants;
  final Map<EmoteEnum, int> emoteCounts;
}
