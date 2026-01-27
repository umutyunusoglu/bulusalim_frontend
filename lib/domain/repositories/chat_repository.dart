import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/chat/message_entity.dart';

abstract class ChatRepository {
  Stream<List<MessageEntity>> getChatMessagesStream(Identifier eventID);
  Future<void> sendMessage(Identifier eventID, MessageEntity message);
}
