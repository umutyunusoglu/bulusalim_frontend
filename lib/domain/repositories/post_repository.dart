import 'package:outnest/core/utils/types/enums/emote_enum.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/entities/hobby/hobby_entity.dart';

abstract class PostRepository {
  Future<void> createPost(PostEntity post, bool isPinned);
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

  Future<void> pinPost(
    Identifier postId,
    Identifier userId,
  );

  Future<void> unpinPost(
    Identifier postId,
    Identifier userId,
  );

  Future<void> addEmoteToPost(
    Identifier postId,
    Identifier userId,
    EmoteEnum emote,
  );

  Future<void> removeEmoteFromPost(
    Identifier postId,
    Identifier userId,
    EmoteEnum emote,
  );
  Future<bool> isUserEmotedPost(
    Identifier postId,
    Identifier userId,
    EmoteEnum emote,
  );
}
