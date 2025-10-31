import 'package:bulusalim/core/utils/types/enums/emote_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:equatable/equatable.dart';

class PostEntity extends Equatable {
  const PostEntity({
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

  PostEntity copyWith({
    Identifier? postID,
    Identifier? userID,
    Identifier? eventID,
    String? title,
    PostMetadata? metadata,
    Geolocation? location,
    List<HobbyEntity>? hobbies,
    List<String>? photoUrls,
    List<Identifier>? participants,
    Map<EmoteEnum, int>? emoteCounts,
  }) {
    return PostEntity(
      postID: postID ?? this.postID,
      userID: userID ?? this.userID,
      eventID: eventID ?? this.eventID,
      title: title ?? this.title,
      metadata: metadata ?? this.metadata,
      location: location ?? this.location,
      hobbies: hobbies ?? this.hobbies,
      photoUrls: photoUrls ?? this.photoUrls,
      participants: participants ?? this.participants,
      emoteCounts: emoteCounts ?? this.emoteCounts,
    );
  }

  @override
  List<Object?> get props => [
    postID,
    userID,
  ];

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

class PostMetadata {
  const PostMetadata({
    required this.createdAt,
    required this.updatedAt,
  });
  factory PostMetadata.fromMap(Map<String, dynamic> map) {
    final keys = [
      'createdAt',
      'updatedAt',
    ];

    for (final key in keys) {
      if (!map.containsKey(key)) {
        throw Exception('Missing key: $key');
      }
    }

    return PostMetadata(
      createdAt: map['createdAt'] as DateTime,
      updatedAt: map['updatedAt'] as DateTime,
    );
  }
  PostMetadata copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostMetadata(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  final DateTime createdAt;
  final DateTime updatedAt;
}
