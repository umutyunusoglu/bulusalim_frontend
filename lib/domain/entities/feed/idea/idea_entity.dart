// domain/entities/feed/idea/idea_entity.dart

import 'package:outnest/core/utils/types/enums/feed_entity_type_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';

/// A short, tweet-like opinion that users can post to the feed.
///
/// Ideas support like/dislike voting (mutually exclusive — a user
/// either likes, dislikes, or neither) and an unbounded comment
/// thread. Comments live in a subcollection and are loaded lazily
/// per-branch rather than as a single flat tree, so deep threads
/// stay cheap.
class IdeaEntity extends FeedEntity {
  IdeaEntity({
    required Identifier id,
    required this.creator,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.likeCount,
    required this.dislikeCount,
    required this.commentCount,
    required this.commentsEnabled,
    this.currentUserVote,
  }) : super(id: id, feedType: FeedEntityTypeEnum.idea);

  final CompactUserEntity creator;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final bool commentsEnabled;

  /// The current user's vote on this idea, or null if they haven't
  /// voted. Populated by the repository at fetch time so the UI can
  /// render filled/outlined icons without a per-card round-trip.
  final IdeaVoteType? currentUserVote;

  @override
  DateTime get sortDate => updatedAt ?? createdAt;

  IdeaEntity copyWith({
    int? likeCount,
    int? dislikeCount,
    int? commentCount,
    bool? commentsEnabled,
    IdeaVoteType? currentUserVote,
    bool clearVote = false,
  }) {
    return IdeaEntity(
      id: id,
      creator: creator,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      commentCount: commentCount ?? this.commentCount,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      currentUserVote: clearVote
          ? null
          : (currentUserVote ?? this.currentUserVote),
    );
  }
}

enum IdeaVoteType {
  like._('like'),
  dislike._('dislike');

  const IdeaVoteType._(this.value);
  final String value;

  @override
  String toString() => value;

  static IdeaVoteType? fromString(String? value) {
    switch (value) {
      case 'like':
        return like;
      case 'dislike':
        return dislike;
      default:
        return null;
    }
  }
}
