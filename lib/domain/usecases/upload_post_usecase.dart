import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
import 'package:bulusalim/domain/repositories/post_repository.dart';
import 'package:bulusalim/domain/services/file_service.dart';

class UploadPost {
  UploadPost({
    required LoggingService logger,
    required PostRepository postRepository,
    required FileService fileService,
  }) : _logger = logger,
       _postRepository = postRepository,
       _fileService = fileService;

  final LoggingService _logger;
  final PostRepository _postRepository;
  final FileService _fileService;

  Future<PostEntity> call(
    PostEntity post,
    List<PostParticipantEntity> participants,
    List<String> filePaths,
  ) async {
    final uploadUrls = <String>[];

    if (filePaths.isNotEmpty) {
      _logger.info('Uploading images for post: ${post.postID}');
      for (final path in filePaths) {
        final url = await _fileService.uploadFile(
          path,
          FileService.publicImages,
        );
        uploadUrls.add(url);
      }
      _logger.info('Images uploaded for post: ${post.postID}');
    }

    final updatedPost = post.copyWith(
      imageUrls: uploadUrls,
      participants: participants,
    );

    _logger.info('Uploading post: ${post.postID}');
    await _postRepository.createPost(updatedPost);

    _logger.info('Post uploaded: ${post.postID}');
    return updatedPost;
  }
}
