import 'package:outnest/core/utils/types/types.dart';

class MessageEntity {
  MessageEntity({
    required this.content,
    required this.senderID,
    required this.username,
    required this.profileImageUrl,
    required this.createdAt,
  });

  final String content;
  final Identifier senderID;
  final String username;
  final String profileImageUrl;
  final DateTime createdAt;
}
