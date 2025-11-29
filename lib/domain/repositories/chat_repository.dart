import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/chat/message_entity.dart';

abstract class ChatRepository {
  Stream<List<MessageEntity>> getChatMessagesStream(Identifier eventID);
  Future<void> sendMessage(Identifier eventID, MessageEntity message);
}
