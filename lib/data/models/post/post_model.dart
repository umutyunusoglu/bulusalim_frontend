import 'package:bulusalim/application/providers/getIt_init.dart';
import 'package:bulusalim/core/utils/types/enums/emote_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:bulusalim/domain/entities/post/post_entity.dart';
import 'package:bulusalim/domain/services/file_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

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
    this.imageUrls,
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
      imageUrls: entity.imageUrls,
      participants: entity.participants,
      emoteCounts: entity.emoteCounts,
    );
  }
  static Future<PostModel> fromFirestore(Map<String, dynamic> doc) async {
    final FileService fileService = getIt<FileService>();

    final imagePaths =
        (doc['imagePaths'] as List<dynamic>?)?.cast<String>().toList() ?? [];

    final imageUrls = await Future.wait(
      imagePaths.map(fileService.getDownloadUrl),
    );

    final location = doc['location'] as GeoPoint;
    final locationMap = {
      "latitude": location.latitude,
      "longitude": location.longitude,
    };
    return PostModel(
      postID: doc['postID'] as String,
      userID: doc['userID'] as String,
      eventID: doc['eventID'] as String,
      title: doc['title'] as String,
      metadata: PostMetadata(
        createdAt: DateTime(2003),
        updatedAt: DateTime(2000),
      ), //TODO
      location: Geolocation.fromMap(locationMap),
      hobbies: (doc['hobbies'] as List<dynamic>)
          .map((hobby) => HobbyEntity.fromString(hobby as String))
          .toList(),
      imageUrls: imageUrls,
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
      imageUrls: imageUrls,
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
      'imagePaths': imageUrls,
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
  final List<String>? imageUrls;
  final List<Identifier> participants;
  final Map<EmoteEnum, int> emoteCounts;
}
