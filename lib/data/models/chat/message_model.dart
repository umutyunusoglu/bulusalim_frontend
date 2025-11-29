import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/chat/message_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel implements Model<MessageEntity> {
  MessageModel({
    required this.content,
    required this.senderID,
    required this.timestamp,
  });
  factory MessageModel.fromFirestore(
    Map<String, dynamic> firestoreData,
  ) {
    return MessageModel(
      content: firestoreData['content'] as String,
      senderID: firestoreData['senderID'] as String,
      timestamp: firestoreData['createdAt'] as DateTime,
    );
  }

  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      content: entity.content,
      senderID: entity.senderID,
      timestamp: entity.timestamp,
    );
  }

  final String content;
  final String senderID;
  final DateTime? timestamp;

  @override
  MessageEntity toEntity() {
    return MessageEntity(
      content: content,
      senderID: senderID,
      timestamp: timestamp!,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'senderID': senderID,
      'createdAt': timestamp ?? FieldValue.serverTimestamp(),
    };
  }
}
