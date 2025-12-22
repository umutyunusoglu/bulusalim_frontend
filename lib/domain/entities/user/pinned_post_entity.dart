import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
import 'package:equatable/equatable.dart';

class PinnedPostEntity with EquatableMixin {
  PinnedPostEntity({
    required this.postID,
    required this.caption,
    required this.location,
    required this.imageUrls,
    required this.participants,
    required this.emoteCounts,
    required this.createdAt,
  });

  PinnedPostEntity copyWith({
    String? postID,
    String? caption,
    Geolocation? geolocation,
    List<String>? imageUrls,
    List<PostParticipantEntity>? participants,
    Map<String, int>? emoteCounts,
    DateTime? createdAt,
  }) {
    return PinnedPostEntity(
      postID: postID ?? this.postID,
      caption: caption ?? this.caption,
      location: geolocation ?? location,
      imageUrls: imageUrls ?? this.imageUrls,
      participants: participants ?? this.participants,
      emoteCounts: emoteCounts ?? this.emoteCounts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [postID];

  final String postID;
  final String caption;
  final Geolocation location;
  final List<String> imageUrls;
  final List<PostParticipantEntity> participants;
  final Map<String, int> emoteCounts;
  final DateTime createdAt;
}
