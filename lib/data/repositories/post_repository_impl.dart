import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/enums/emote_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/distance.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/post/post_model.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:bulusalim/domain/entities/post/post_entity.dart';
import 'package:bulusalim/domain/repositories/post_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl({
    required FirebaseFirestore firestore,
    required LoggingService logger,
  }) : _firestore = firestore,
       _logger = logger;

  final FirebaseFirestore _firestore;
  final LoggingService _logger;

  @override
  Future<void> createPost(PostEntity post) async {
    try {
      final docRef = _firestore.collection('posts').doc();
      final postWithID = post.copyWith(postID: docRef.id);
      final postModel = PostModel.fromEntity(postWithID);

      await docRef.set(postModel.toFirestore());
    } catch (e) {
      _logger.error('Failed to create post: $e');
      rethrow;
    }
  }

  @override
  Future<void> deletePost(Identifier postId) async {
    try {
      final docRef = _firestore.collection('posts').doc(postId);
      await docRef.delete();
    } catch (e) {
      _logger.error('Failed to delete post: $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePost(PostEntity post) async {
    try {
      final docRef = _firestore.collection('posts').doc(post.postID);
      final postModel = PostModel.fromEntity(post);

      await docRef.update(postModel.toFirestore());
    } catch (e) {
      _logger.error('Failed to update post: $e');
      rethrow;
    }
  }

  @override
  Future<PostEntity?> getPostById(Identifier postId) async {
    try {
      final docRef = _firestore.collection('posts').doc(postId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final postModel = PostModel.fromFirestore(docSnapshot.data()!);
        return postModel.toEntity();
      } else {
        return null;
      }
    } catch (e) {
      _logger.error('Failed to get post by ID: $e');
      rethrow;
    }
  }

  @override
  Future<List<PostEntity>> getPostsByUserId(Identifier userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc.data()).toEntity())
          .toList();
    } catch (e) {
      _logger.error('Failed to get posts by user ID: $e');
      rethrow;
    }
  }

  @override
  Future<List<PostEntity>> getAllPosts() {
    final querySnapshot = _firestore.collection('posts').get();

    return querySnapshot.then(
      (snapshot) => snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc.data()).toEntity())
          .toList(),
    );
  }

  @override
  Future<List<PostEntity>> getPostsByEventId(Identifier eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('eventID', isEqualTo: eventId)
          .get();

      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc.data()).toEntity())
          .toList();
    } catch (e) {
      _logger.error('Failed to get posts by event ID: $e');
      rethrow;
    }
  }

  @override
  Future<List<PostEntity>> getPostsByHobby(HobbyEntity hobby) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('hobbies', arrayContains: hobby.name)
          .get();

      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc.data()).toEntity())
          .toList();
    } catch (e) {
      _logger.error('Failed to get posts by hobby: $e');
      rethrow;
    }
  }

  @override
  Future<List<PostEntity>> getPostsByLocation(
    Geolocation location,
    double radiusInKm,
  ) async {
    final querySnapshot = await _firestore.collection('posts').get();

    return querySnapshot.docs
        .map((doc) => PostModel.fromFirestore(doc.data()))
        .where((data) {
          final d = haversineDistance(
            lat1: location.latitude,
            lon1: location.longitude,
            lat2: data.location!.latitude,
            lon2: data.location!.longitude,
          );

          return d <= radiusInKm;
        })
        .map((data) => data.toEntity())
        .toList();
  }

  @override
  Future<void> addEmoteToPost(
    Identifier postId,
    EmoteEnum emote,
  ) async {
    final docRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Post not found');
      }

      final postModel = PostModel.fromFirestore(snapshot.data()!);
      final currentCount = postModel.emoteCounts[emote] ?? 0;
      postModel.emoteCounts[emote] = currentCount + 1;

      transaction.update(docRef, postModel.toFirestore());
    });
  }

  @override
  Future<void> removeEmoteFromPost(
    Identifier postId,
    EmoteEnum emote,
  ) async {
    final docRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Post not found');
      }

      final postModel = PostModel.fromFirestore(snapshot.data()!);
      final currentCount = postModel.emoteCounts[emote] ?? 0;
      if (currentCount > 0) {
        postModel.emoteCounts[emote] = currentCount - 1;

        transaction.update(docRef, postModel.toFirestore());
      }
    });
  }
}
