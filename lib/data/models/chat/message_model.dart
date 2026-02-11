import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/data/models/model.dart';
import 'package:outnest/domain/entities/chat/message_entity.dart';

class MessageModel implements Model<MessageEntity> {
  MessageModel({
    required this.content,
    required this.senderID,
    required this.createdAt,
  });
  factory MessageModel.fromFirestore(
    Map<String, dynamic> firestoreData,
  ) {
    if (firestoreData['createdAt'] == null) {}
    return MessageModel(
      content: firestoreData['content'] as String,
      senderID: firestoreData['senderID'] as String,
      createdAt: (firestoreData['createdAt'] as Timestamp).toDate(),
    );
  }

  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      content: entity.content,
      senderID: entity.senderID,
      createdAt: entity.createdAt,
    );
  }

  final String content;
  final String senderID;
  final DateTime? createdAt;

  @override
  MessageEntity toEntity() {
    return MessageEntity(
      content: content,
      senderID: senderID,
      createdAt: createdAt!,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    final timestamp = createdAt != null ? Timestamp.fromDate(createdAt!) : null;
    return {
      'content': content,
      'senderID': senderID,
      'createdAt': timestamp ?? FieldValue.serverTimestamp(),
    };
  }
}
