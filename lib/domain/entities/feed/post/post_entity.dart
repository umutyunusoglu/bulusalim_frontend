import 'package:equatable/equatable.dart';
import 'package:outnest/core/utils/types/enums/emote_enum.dart';
import 'package:outnest/core/utils/types/enums/feed_entity_type_enum.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';
import 'package:outnest/domain/entities/hobby/hobby_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';

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
    required this.imageUrls,
    required this.isPinned,
    this.location,
    this.displayAddress,
  }) : super(feedType: FeedEntityTypeEnum.post, id: postID);

  PostEntity copyWith({
    Identifier? postID,
    CompactUserEntity? creator,
    Identifier? eventID,
    String? caption,
    Geolocation? location,
    String? displayAddress,
    List<HobbyEntity>? hobbies,
    List<String>? imageUrls,
    List<CompactUserEntity>? participants,
    Map<EmoteEnum, int>? emoteCounts,
    UserEntity? user,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? showParticipants,
    bool? includeInDump,
    bool? isPinned,
  }) {
    return PostEntity(
      postID: postID ?? this.postID,
      creator: creator ?? this.creator,
      eventID: eventID ?? this.eventID,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      displayAddress: displayAddress ?? this.displayAddress,
      hobbies: hobbies ?? this.hobbies,
      imageUrls: imageUrls ?? this.imageUrls,
      participants: participants ?? this.participants,
      emoteCounts: emoteCounts ?? this.emoteCounts,
      showParticipants: showParticipants ?? this.showParticipants,
      includeInDump: includeInDump ?? this.includeInDump,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  List<Object?> get props => [
    postID,
    creator,
    eventID,
    isPinned,
  ];

  final Identifier postID;
  final CompactUserEntity creator;
  final Identifier eventID;
  final String caption;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Geolocation? location;
  final String? displayAddress;
  final List<HobbyEntity> hobbies;
  final List<String> imageUrls;
  final bool showParticipants;
  final bool includeInDump;
  final List<CompactUserEntity> participants;
  final Map<EmoteEnum, int> emoteCounts;
  final bool isPinned;
}
