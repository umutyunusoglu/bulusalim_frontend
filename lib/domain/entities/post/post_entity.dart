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
    required this.hobbies,
    required this.participants,
    required this.emoteCounts,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.imageUrls,
  });

  PostEntity copyWith({
    Identifier? postID,
    Identifier? userID,
    Identifier? eventID,
    String? title,
    Geolocation? location,
    List<HobbyEntity>? hobbies,
    List<String>? imageUrls,
    List<Identifier>? participants,
    Map<EmoteEnum, int>? emoteCounts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostEntity(
      postID: postID ?? this.postID,
      userID: userID ?? this.userID,
      eventID: eventID ?? this.eventID,
      title: title ?? this.title,

      location: location ?? this.location,
      hobbies: hobbies ?? this.hobbies,
      imageUrls: imageUrls ?? this.imageUrls,
      participants: participants ?? this.participants,
      emoteCounts: emoteCounts ?? this.emoteCounts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final Geolocation? location;
  final List<HobbyEntity> hobbies;
  final List<String>? imageUrls;
  final List<Identifier> participants;
  final Map<EmoteEnum, int> emoteCounts;
}
