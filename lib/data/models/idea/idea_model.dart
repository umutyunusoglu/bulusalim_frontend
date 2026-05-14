// data/models/idea/idea_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/idea/idea_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';

/// Firestore mapping for an idea document.
///
/// Wire format:
/// ```
/// ideas/{ideaId}
///   creator: { CompactUserEntity map }
///   content: string
///   createdAt, updatedAt: Timestamp
///   likeCount, dislikeCount, commentCount: int
///   commentsEnabled: bool
///   status: 'active' | 'deleted'
/// ```
///
/// [currentUserVote] is not part of the document — it lives in the
/// `votes` subcollection and is joined in by the source layer.
class IdeaModel {
  IdeaModel({
    required this.id,
    required this.creator,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.likeCount,
    required this.dislikeCount,
    required this.commentCount,
    required this.commentsEnabled,
    required this.status,
  });

  final Identifier id;
  final CompactUserEntity creator;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final bool commentsEnabled;
  final String status;

  static const statusActive = 'active';
  static const statusDeleted = 'deleted';

  bool get isDeleted => status == statusDeleted;

  factory IdeaModel.fromFirestore(Map<String, dynamic> data) {
    return IdeaModel(
      id: data['id'] as Identifier,
      creator: CompactUserEntity.fromMap(
        Map<String, dynamic>.from(data['creator'] as Map),
      ),
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      likeCount: data['likeCount'] as int? ?? 0,
      dislikeCount: data['dislikeCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      commentsEnabled: data['commentsEnabled'] as bool? ?? true,
      status: data['status'] as String? ?? statusActive,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'creator': creator.toMap(),
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'commentCount': commentCount,
      'commentsEnabled': commentsEnabled,
      'status': status,
    };
  }

  /// Converts to a domain entity. [currentUserVote] is left null —
  /// callers that need it (the feed source, detail page) should
  /// resolve it and pass it via [IdeaEntity.copyWith].
  IdeaEntity toEntity({IdeaVoteType? currentUserVote}) {
    return IdeaEntity(
      id: id,
      creator: creator,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likeCount: likeCount,
      dislikeCount: dislikeCount,
      commentCount: commentCount,
      commentsEnabled: commentsEnabled,
      currentUserVote: currentUserVote,
    );
  }
}
