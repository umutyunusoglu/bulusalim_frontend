import 'package:bulusalim/core/utils/types/enums/emote_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';

abstract class PostRepository {
  Future<void> createPost(PostEntity post);
  Future<void> deletePost(Identifier postId);
  Future<void> updatePost(PostEntity post);

  Future<PostEntity?> getPostById(Identifier postId);
  Future<List<PostEntity>> getPostsByUserId(Identifier userId);
  Future<List<PostEntity>> getAllPosts();
  Future<List<PostEntity>> getPostsByEventId(Identifier eventId);
  Future<List<PostEntity>> getPostsByHobby(HobbyEntity hobby);
  Future<List<PostEntity>> getPostsByLocation(
    Geolocation location,
    double radiusInKm,
  );

  Future<List<PostEntity>> fetchNextBatchOfPosts(
    PostEntity? lastPost,
    int batchSize,
  );

  Future<List<PostEntity>> fetchPreviousBatchOfPosts(
    PostEntity firstPost,
    int batchSize,
  );

  Future<void> addEmoteToPost(
    Identifier postId,
    EmoteEnum emote,
  );

  Future<void> removeEmoteFromPost(
    Identifier postId,
    EmoteEnum emote,
  );
}
