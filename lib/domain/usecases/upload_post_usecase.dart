import 'dart:io';

import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/feed/post/post_entity.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:bulusalim/domain/repositories/post_repository.dart';
import 'package:bulusalim/domain/services/file_service.dart';
import 'package:bulusalim/domain/services/session_service.dart';

class UploadPost {
  UploadPost({
    required LoggingService logger,
    required PostRepository postRepository,
    required FileService fileService,
    required SessionService sessionService,
  }) : _logger = logger,
       _postRepository = postRepository,
       _fileService = fileService,
       _sessionService = sessionService;

  final LoggingService _logger;
  final PostRepository _postRepository;
  final FileService _fileService;
  final SessionService _sessionService;

  Future<PostEntity> call(
    EventEntity currentEvent,
    List<File> files,
    bool showParticipants,
    bool addToDump,
    String caption,
  ) async {
    final uploadUrls = <String>[];

    if (files.isNotEmpty) {
      for (final file in files) {
        final postname = file.path.split('/').last;
        final url = await _fileService.uploadFile(
          file,
          '${FileService.privateUsers}/${_sessionService.currentUser!.userID}/posts/images/$postname',
        );

        uploadUrls.add(url);
      }
    }

    final currentUser = _sessionService.currentUser!;
    final creator = PostParticipantEntity(
      userID: currentUser.userID,
      username: currentUser.username,
      profileImageUrl: currentUser.profileImageUrl,
    );

    final post = PostEntity(
      postID: '',
      creator: creator,
      eventID: currentEvent.eventID,
      caption: caption,
      hobbies: currentEvent.hobbies
          .map((hobby) => HobbyEntity.fromString(hobby))
          .toList(),

      showParticipants: showParticipants,
      includeInDump: addToDump,
      participants: currentEvent.participants
          .map(
            (participant) => PostParticipantEntity(
              userID: participant.userID,
              username: participant.username,
              profileImageUrl: participant.profileImageUrl,
            ),
          )
          .toList(),
      emoteCounts: {},
      imageUrls: uploadUrls,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      location: currentEvent.location,
    );

    _logger.info('Uploading post: ${post.postID}');
    await _postRepository.createPost(post);

    _logger.info('Post uploaded: ${post.postID}');
    return post;
  }
}
