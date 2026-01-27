import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:equatable/equatable.dart';

class UserPostEntity with EquatableMixin {
  UserPostEntity({
    required this.postID,
    required this.caption,
    required this.location,
    required this.imageUrls,
    required this.participants,
    required this.emoteCounts,
    required this.isPinned,
    required this.createdAt,
  });

  UserPostEntity copyWith({
    String? postID,
    String? caption,
    Geolocation? location,
    List<String>? imageUrls,
    List<CompactUserEntity>? participants,
    Map<String, int>? emoteCounts,
    bool? isPinned,
    DateTime? createdAt,
  }) {
    return UserPostEntity(
      postID: postID ?? this.postID,
      caption: caption ?? this.caption,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      participants: participants ?? this.participants,
      emoteCounts: emoteCounts ?? this.emoteCounts,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [postID];

  final String postID;
  final String caption;
  final Geolocation location;
  final List<String> imageUrls;
  final List<CompactUserEntity> participants;
  final Map<String, int> emoteCounts;
  final bool isPinned;
  final DateTime createdAt;
}
