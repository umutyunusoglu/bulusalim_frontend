import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/data/models/model.dart';
import 'package:outnest/domain/entities/chat/message_entity.dart';

class MessageModel implements Model<MessageEntity> {
  MessageModel({
    required this.content,
    required this.senderID,
    required this.createdAt,
    required this.profileImageUrl,
    required this.username,
  });

  factory MessageModel.fromFirestore(
    Map<String, dynamic> firestoreData,
  ) {
    return MessageModel(
      content: firestoreData['content'] as String? ?? "",
      senderID: firestoreData['senderID'] as String? ?? "",
      // createdAt null gelirse şu anki zamanı ata
      createdAt:
          (firestoreData['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      // Null gelme ihtimaline karşı cast işlemini String? yaparak koruyoruz
      username: firestoreData['username'] as String? ?? "Bilinmeyen Kullanıcı",
      profileImageUrl: firestoreData['profileImageUrl'] as String? ?? "",
    );
  }

  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      content: entity.content,
      senderID: entity.senderID,
      createdAt: entity.createdAt,
      username: entity.username,
      profileImageUrl: entity.profileImageUrl,
    );
  }

  final String content;
  final String senderID;
  final DateTime createdAt;
  final String username;
  final String profileImageUrl;

  @override
  MessageEntity toEntity() {
    return MessageEntity(
      content: content,
      senderID: senderID,
      createdAt: createdAt,
      username: username,
      profileImageUrl: profileImageUrl,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'senderID': senderID,
      'createdAt': Timestamp.fromDate(createdAt),
      'username': username,
      'profileImageUrl': profileImageUrl,
    };
  }
}
