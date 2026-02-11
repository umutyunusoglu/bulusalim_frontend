import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/data/models/chat/message_model.dart';
import 'package:outnest/domain/entities/chat/message_entity.dart';
import 'package:outnest/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required FirebaseFirestore firestore,
    required LoggingService logger,
  }) : _firestore = firestore,
       _logger = logger;

  final FirebaseFirestore _firestore;
  final LoggingService _logger;

  @override
  Stream<List<MessageEntity>> getChatMessagesStream(
    Identifier eventID,
  ) {
    return _firestore
        .collection('events')
        .doc(eventID)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            if (doc.metadata.hasPendingWrites && data['createdAt'] == null) {
              data['createdAt'] = Timestamp.now();
            }
            final messageModel = MessageModel.fromFirestore(
              data,
            );
            return messageModel.toEntity();
          }).toList();
        });
  }

  @override
  Future<void> sendMessage(Identifier eventID, MessageEntity message) {
    return _firestore
        .collection('events')
        .doc(eventID)
        .collection('messages')
        .add({
          'content': message.content,
          'senderID': message.senderID,
          'createdAt': FieldValue.serverTimestamp(),
        })
        .then((_) {
          _logger.info('Message sent successfully.');
        })
        .catchError((Object error) {
          _logger.error('Failed to send message: $error');
          throw Exception(error);
        });
  }
}
