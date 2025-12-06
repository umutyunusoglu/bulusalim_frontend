import 'package:bulusalim/core/utils/types/enums/emote_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/feed/feed_entity.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:equatable/equatable.dart';

class PostEntity extends FeedEntity with EquatableMixin {
  PostEntity({
    required this.postID,
    required this.creator,
    required this.eventID,
    required this.caption,
    required this.hobbies,
    required this.showParticipants,
    required this.includeInDump,
    required this.participants,
    required this.emoteCounts,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.imageUrls,
  }) : super(feedType: FeedEntityType.post, id: postID);

  PostEntity copyWith({
    Identifier? postID,
    PostParticipantEntity? creator,
    Identifier? eventID,
    String? caption,
    Geolocation? location,
    List<HobbyEntity>? hobbies,
    List<String>? imageUrls,
    List<PostParticipantEntity>? participants,
    Map<EmoteEnum, int>? emoteCounts,
    UserEntity? user,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? showParticipants,
    bool? includeInDump,
  }) {
    return PostEntity(
      postID: postID ?? this.postID,
      creator: creator ?? this.creator,
      eventID: eventID ?? this.eventID,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      hobbies: hobbies ?? this.hobbies,
      imageUrls: imageUrls ?? this.imageUrls,
      participants: participants ?? this.participants,
      emoteCounts: emoteCounts ?? this.emoteCounts,
      showParticipants: showParticipants ?? this.showParticipants,
      includeInDump: includeInDump ?? this.includeInDump,
    );
  }

  @override
  List<Object?> get props => [
    postID,
    creator,
    eventID,
  ];

  final Identifier postID;
  final PostParticipantEntity creator;
  final Identifier eventID;
  final String caption;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Geolocation? location;
  final List<HobbyEntity> hobbies;
  final List<String>? imageUrls;
  final bool showParticipants;
  final bool includeInDump;
  final List<PostParticipantEntity> participants;
  final Map<EmoteEnum, int> emoteCounts;
}

class PostParticipantEntity extends Equatable {
  const PostParticipantEntity({
    required this.userID,
    required this.username,
    required this.profileImageUrl,
  });

  PostParticipantEntity copyWith({
    Identifier? userID,
    String? username,
    String? profileImageUrl,
  }) {
    return PostParticipantEntity(
      userID: userID ?? this.userID,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  factory PostParticipantEntity.fromMap(Map<String, dynamic> map) {
    return PostParticipantEntity(
      userID: map['userID'] as Identifier,
      username: map['username'] as String,
      profileImageUrl: map['profileImageUrl'] as String,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'username': username,
      'profileImageUrl': profileImageUrl,
    };
  }

  @override
  List<Object?> get props => [userID];

  final Identifier userID;
  final String username;
  final String profileImageUrl;
}
