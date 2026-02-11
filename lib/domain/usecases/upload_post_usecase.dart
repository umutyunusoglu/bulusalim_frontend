import 'dart:io';

import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/emote_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/entities/hobby/hobby_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/post_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/session_service.dart';

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
    bool isPinned,
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
    final creator = CompactUserEntity(
      userID: currentUser.userID,
      username: currentUser.username,
      profileImageUrl: currentUser.profileImageUrl,
      university: currentUser.university,
    );

    final post = PostEntity(
      postID: '',
      creator: creator,
      eventID: currentEvent.eventID,
      caption: caption,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      location: currentEvent.location,
      displayAddress: currentEvent.displayAddress,
      hobbies: currentEvent.hobbies
          .map((hobbyName) => HobbyEntity(name: hobbyName))
          .toList(),
      imageUrls: uploadUrls,
      participants: currentEvent.participants,
      emoteCounts: {
        EmoteEnum.heart: 0,
        EmoteEnum.clap: 0,
        EmoteEnum.egg: 0,
      },
      showParticipants: showParticipants,
      includeInDump: addToDump,
      isPinned: isPinned,
    );

    _logger.info('Uploading post: ${post.postID}');
    await _postRepository.createPost(post, isPinned);

    _logger.info('Post uploaded: ${post.postID}');
    return post;
  }
}
