// domain/entities/feed/idea/idea_comment_entity.dart

import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/idea/idea_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';

/// A comment on an [IdeaEntity], or a reply to another comment.
///
/// Threading is represented purely by [parentCommentId]:
///   - null  → top-level comment on the idea
///   - other → reply to that comment, at any depth
///
/// The UI loads top-level comments first and fetches each branch's
/// replies on demand when the user expands them. [replyCount] lets
/// the UI show the "X replies" affordance without a count query.
class IdeaCommentEntity {
  IdeaCommentEntity({
    required this.id,
    required this.ideaId,
    required this.author,
    required this.content,
    required this.parentCommentId,
    required this.createdAt,
    required this.updatedAt,
    required this.likeCount,
    required this.dislikeCount,
    required this.replyCount,
    this.currentUserVote,
  });

  final Identifier id;
  final Identifier ideaId;
  final CompactUserEntity author;
  final String content;
  final Identifier? parentCommentId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final int dislikeCount;
  final int replyCount;
  final IdeaVoteType? currentUserVote;

  bool get isTopLevel => parentCommentId == null;

  IdeaCommentEntity copyWith({
    int? likeCount,
    int? dislikeCount,
    int? replyCount,
    IdeaVoteType? currentUserVote,
    bool clearVote = false,
  }) {
    return IdeaCommentEntity(
      id: id,
      ideaId: ideaId,
      author: author,
      content: content,
      parentCommentId: parentCommentId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      replyCount: replyCount ?? this.replyCount,
      currentUserVote: clearVote
          ? null
          : (currentUserVote ?? this.currentUserVote),
    );
  }
}
