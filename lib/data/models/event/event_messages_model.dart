import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/feed/event/event_messages_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventMessagesModel extends Model<EventMessagesEntity> {
  EventMessagesModel({
    required this.messageID,
    required this.sender,
    required this.content,
    required this.timestamp,
  });

  @override
  factory EventMessagesModel.fromEntity(EventMessagesEntity entity) {
    return EventMessagesModel(
      messageID: entity.messageID,
      sender: entity.sender,
      content: entity.content,
      timestamp: entity.timestamp,
    );
  }
  @override
  factory EventMessagesModel.fromFirestore(Map<String, dynamic> data) {
    return EventMessagesModel(
      messageID: data['messageID'] as Identifier,
      sender: data['sender'] as Identifier,
      content: data['content'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'messageID': messageID,
      'sender': sender,
      'content': content,
      'timestamp': timestamp,
    };
  }

  @override
  EventMessagesEntity toEntity() {
    return EventMessagesEntity(
      messageID: messageID,
      sender: sender,
      content: content,
      timestamp: timestamp,
    );
  }

  final Identifier messageID;
  final Identifier sender;
  final String content;
  final DateTime timestamp;
}
