import 'package:bulusalim/core/utils/types/types.dart';

class MessageEntity {
  MessageEntity({
    required this.content,
    required this.senderID,
    required this.createdAt,
  });

  final String content;
  final Identifier senderID;
  final DateTime createdAt;
}
