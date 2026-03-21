import 'dart:developer' as debug;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/app_state/app_initialization_state.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/data/models/links/deep_link_target.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/services/share_links_service.dart';
import 'package:share_plus/share_plus.dart';

class ShareLinksServiceImpl extends ShareLinksService {
  static const String shareLinkPrefix =
      'https://outnest.app/share'; // This will be the base URL

  final UserRepository userRepository = getIt<UserRepository>();
  final AuthService authService = getIt<AuthService>();
  final SessionService sessionService = getIt<SessionService>();

  static Uri post(String postId) => Uri.parse(
    '$shareLinkPrefix/post/$postId',
  ); // For generating a share link for a post

  static Uri event(String eventId) => Uri.parse(
    '$shareLinkPrefix/event/$eventId',
  ); // For generating a share link for an event

  static Uri user(String userId) => Uri.parse(
    '$shareLinkPrefix/profile/$userId',
  ); // For generating a share link for a user profile

  @override
  Future<void> sharePost(String postId) async {
    final link = post(postId);
    await SharePlus.instance.share(ShareParams(text: link.toString()));
  }

  @override
  Future<void> shareEvent(String eventId) async {
    final link = event(eventId);
    await SharePlus.instance.share(ShareParams(text: link.toString()));
  }

  @override
  Future<void> shareUserProfile(String userId) async {
    final link = user(userId);
    await SharePlus.instance.share(ShareParams(text: link.toString()));
  }
}
