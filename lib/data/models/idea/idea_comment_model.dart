// data/models/idea/idea_comment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/idea/idea_comment_entity.dart';
import 'package:outnest/domain/entities/feed/idea/idea_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';

/// Firestore mapping for a comment document.
///
/// Wire format:
/// ```
/// ideas/{ideaId}/comments/{commentId}
///   author: { CompactUserEntity map }
///   content: string
///   parentCommentId: string?    // null → top-level
///   createdAt, updatedAt: Timestamp
///   likeCount, dislikeCount, replyCount: int
///   status: 'active' | 'deleted'
/// ```
class IdeaCommentModel {
  IdeaCommentModel({
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
    required this.status,
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
  final String status;

  static const statusActive = 'active';
  static const statusDeleted = 'deleted';

  bool get isDeleted => status == statusDeleted;

  /// Sentinel value used in Firestore for top-level comments. The
  /// repository writes this instead of `null` to make
  /// `whereEqualTo` queries on `parentCommentId` reliable; we
  /// translate it back to `null` in [fromFirestore] so the domain
  /// layer never sees the wire format.
  ///
  /// Exposed (not private) so [IdeaRepositoryImpl] can use the same
  /// constant when constructing queries — keeps wire format and
  /// query format in lockstep.
  static const rootParentId = '__root__';

  factory IdeaCommentModel.fromFirestore({
    required Map<String, dynamic> data,
    required Identifier ideaId,
  }) {
    final rawParent = data['parentCommentId'] as Identifier?;
    final parentCommentId = (rawParent == null || rawParent == rootParentId)
        ? null
        : rawParent;

    return IdeaCommentModel(
      id: data['id'] as Identifier,
      ideaId: ideaId,
      author: CompactUserEntity.fromMap(
        Map<String, dynamic>.from(data['author'] as Map),
      ),
      content: data['content'] as String? ?? '',
      parentCommentId: parentCommentId,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      likeCount: data['likeCount'] as int? ?? 0,
      dislikeCount: data['dislikeCount'] as int? ?? 0,
      replyCount: data['replyCount'] as int? ?? 0,
      status: data['status'] as String? ?? statusActive,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'author': author.toMap(),
      'content': content,
      'parentCommentId': parentCommentId ?? rootParentId,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'replyCount': replyCount,
      'status': status,
    };
  }

  IdeaCommentEntity toEntity({IdeaVoteType? currentUserVote}) {
    return IdeaCommentEntity(
      id: id,
      ideaId: ideaId,
      author: author,
      content: content,
      parentCommentId: parentCommentId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likeCount: likeCount,
      dislikeCount: dislikeCount,
      replyCount: replyCount,
      currentUserVote: currentUserVote,
    );
  }
}
