import 'package:outnest/core/utils/types/types.dart';
import 'package:equatable/equatable.dart';

class EventMessagesEntity extends Equatable {
  const EventMessagesEntity({
    required this.messageID,
    required this.sender,
    required this.content,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [messageID, sender, content, timestamp];

  EventMessagesEntity copyWith({
    Identifier? messageID,
    Identifier? sender,
    String? content,
    DateTime? timestamp,
  }) {
    return EventMessagesEntity(
      messageID: messageID ?? this.messageID,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  final Identifier messageID;
  final Identifier sender;
  final String content;
  final DateTime timestamp;
}
