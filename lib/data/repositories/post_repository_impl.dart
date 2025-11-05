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
        final postModel = await PostModel.fromFirestore(docSnapshot.data()!);
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
          final model = await PostModel.fromFirestore(doc.data());
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
          final model = await PostModel.fromFirestore(doc.data());
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
          final model = await PostModel.fromFirestore(doc.data());
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
          final model = await PostModel.fromFirestore(doc.data());
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
        final model = await PostModel.fromFirestore(doc.data());
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

  @override
  Future<void> addEmoteToPost(
    Identifier postId,
    EmoteEnum emote,
  ) async {
    final docRef = _firestore.collection('posts').doc(postId);

    // Belirli bir emote sayacını artırmak için kullanılacak alan yolu
    // Örn: 'emoteCounts.HAPPY'
    final fieldPath = 'emoteCounts.${emote.name}';

    // Güncelleme verisi
    final updateData = {
      fieldPath: FieldValue.increment(1),
    };

    try {
      // İşlem (Transaction) kullanmaya GEREK YOK.
      // increment() metodu zaten sunucuda atomik olarak çalışır.
      await docRef.update(updateData);
    } on FirebaseException catch (e) {
      // Belge bulunamazsa (Post not found) update metodu hata verir
      if (e.code == 'not-found') {
        throw Exception('Post not found: ${postId}');
      }
      // Diğer Firebase hatalarını işle
      rethrow;
    } catch (e) {
      // Diğer hataları işle
      rethrow;
    }
  }

  @override
  Future<void> removeEmoteFromPost(
    Identifier postId,
    EmoteEnum emote,
  ) async {
    final docRef = _firestore.collection('posts').doc(postId);

    // Belirli bir emote sayacını azaltmak için kullanılacak alan yolu
    final fieldPath = 'emoteCounts.${emote.name}';

    // Güncelleme verisi: Sayacı 1 azalt
    final updateData = {
      fieldPath: FieldValue.increment(-1), // Fark: -1 kullanılıyor
    };

    try {
      // İşlem kullanmaya gerek yok, increment atomiktir.
      await docRef.update(updateData);
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw Exception('Post not found: ${postId}');
      }
      rethrow;
    }
  }
}
