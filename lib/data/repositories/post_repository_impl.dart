import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/enums/emote_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/distance.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/post/post_model.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:bulusalim/domain/repositories/post_repository.dart';
import 'package:bulusalim/domain/services/in_memory_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl({
    required FirebaseFirestore firestore,
    required LoggingService logger,
  }) : _firestore = firestore,
       _logger = logger;

  final FirebaseFirestore _firestore;
  final LoggingService _logger;

  final cache = InMemoryCache<PostEntity>(
    cacheSizeLimit: 100,
    ttl: const Duration(minutes: 2),
  );

  @override
  Future<void> createPost(PostEntity post) async {
    try {
      final docRef = _firestore.collection('posts').doc();

      final postWithID = post.copyWith(
        postID: docRef.id,
      );

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

      // her doc için async işlem yapacağın için Future.wait kullan
      final posts = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final model = PostModel.fromFirestore(doc.data());
          return model.toEntity();
        }),
      );

      return posts;
    } catch (e) {
      _logger.error('Failed to get posts by user ID: $e');
      rethrow;
    }
  }

  @override
  Future<List<PostEntity>> getAllPosts() async {
    try {
      final snapshot = await _firestore.collection('posts').get();

      final posts = await Future.wait(
        snapshot.docs.map((doc) async {
          final model = PostModel.fromFirestore(doc.data());
          return model.toEntity();
        }),
      );

      return posts;
    } catch (e) {
      _logger.error('Failed to get all posts: $e');
      rethrow;
    }
  }

  @override
  Future<List<PostEntity>> getPostsByEventId(Identifier eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('eventID', isEqualTo: eventId)
          .get();

      final posts = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final model = PostModel.fromFirestore(doc.data());
          return model.toEntity();
        }),
      );

      return posts;
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

      final posts = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final model = PostModel.fromFirestore(doc.data());
          return model.toEntity();
        }),
      );

      return posts;
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
    final snapshot = await _firestore.collection('posts').get();

    final models = await Future.wait(
      snapshot.docs.map((doc) async {
        final model = PostModel.fromFirestore(doc.data());
        return model;
      }),
    );

    final filtered = models
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

    return filtered;
  }

  // Yardımcı metot: ID oluşturma standardı
  String _generateReactionId(String userId, EmoteEnum emote) {
    return '${userId}_${emote.name}';
  }

  @override
  Future<void> addEmoteToPost(
    Identifier postId,
    Identifier userId,
    EmoteEnum emote,
  ) async {
    final postRef = _firestore.collection('posts').doc(postId);

    // DÜZELTME: ID artık "userId_emoteName" formatında.
    // Böylece user123_heart ve user123_laugh aynı anda var olabilir.
    final reactionDocId = _generateReactionId(userId, emote);
    final emoteRef = postRef.collection('emotes').doc(reactionDocId);

    final batch = _firestore.batch();

    // 1. Post üzerindeki spesifik emoji sayacını arttır
    final fieldPath = 'emoteCounts.${emote.name}';
    batch.update(postRef, {
      fieldPath: FieldValue.increment(1),
    });

    // 2. Reaksiyonu yaz.
    // Eğer kullanıcı daha önce bu emojiyi atmışsa 'set' ile üzerine yazar (sorun olmaz)
    // Ama tekrar basmayı engellemek istersen UI'da kontrol etmelisin.
    batch.set(emoteRef, {
      'emote': emote.name,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> removeEmoteFromPost(
    Identifier postId,
    Identifier userId,

    EmoteEnum emote,
  ) async {
    final postRef = _firestore.collection('posts').doc(postId);

    // DÜZELTME: Silerken de aynı ID formatını kullanıyoruz.
    // Böylece 'where' sorgusu atıp para harcamadan direkt adresten siliyoruz.
    final reactionDocId = _generateReactionId(userId, emote);
    final emoteRef = postRef.collection('emotes').doc(reactionDocId);

    final batch = _firestore.batch();

    // 1. Sayacı azalt
    final fieldPath = 'emoteCounts.${emote.name}';
    batch.update(postRef, {
      fieldPath: FieldValue.increment(-1),
    });

    // 2. Direkt silme işlemi
    batch.delete(emoteRef);

    try {
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isUserEmotedPost(
    Identifier postId,
    Identifier userId,
    EmoteEnum emote,
  ) async {
    try {
      // Belirli bir emojiyi atıp atmadığını kontrol etmek çok ucuz ve hızlı:
      final reactionDocId = _generateReactionId(userId, emote);

      final docSnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('emotes')
          .doc(reactionDocId)
          .get();

      return docSnapshot.exists;
    } on Exception {
      return false;
    }
  }
}
