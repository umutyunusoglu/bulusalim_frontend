import 'package:bulusalim/core/utils/types/enums/restriction_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:equatable/equatable.dart';

class EventEntity extends Equatable {
  const EventEntity({
    required this.eventId,
    required this.name,
    required this.hobbies,
    required this.creator,
    required this.capacity,
    required this.participants,
    required this.participantScores,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.attributes,
    required this.metadata,
    this.info,
  });

  EventEntity copyWith({
    String? eventId,
    String? name,
    String? info,
    List<String>? hobbies,
    Identifier? creator,
    int? capacity,
    List<Identifier>? participants,
    Map<Identifier, int>? participantScores,
    DateTime? startTime,
    DateTime? endTime,
    Geolocation? location,
    EventAttributes? attributes,
    EventMetadata? metadata,
  }) {
    return EventEntity(
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      info: info ?? this.info,
      hobbies: hobbies ?? this.hobbies,
      creator: creator ?? this.creator,
      capacity: capacity ?? this.capacity,
      participants: participants ?? this.participants,
      participantScores: participantScores ?? this.participantScores,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      attributes: attributes ?? this.attributes,
      metadata: metadata ?? this.metadata,
    );
  }

  final String eventId;
  final String name;
  final String? info;
  final List<String> hobbies;
  final Identifier creator;
  final int capacity;
  final List<Identifier> participants;
  final Map<Identifier, int> participantScores;
  final DateTime startTime;
  final DateTime endTime;
  final Geolocation location;
  final EventAttributes attributes;
  final EventMetadata metadata;

  @override
  List<Object?> get props => [
    eventId,
    name,
    info,
    hobbies,
    creator,
    capacity,
    participants,
    participantScores,
    startTime,
    endTime,
    location,
    attributes,
    metadata,
  ];
}

class EventAttributes extends Equatable {
  const EventAttributes({
    required this.price,
    required this.smoking,
    required this.alcohol,
    required this.isPublic,
  });

  factory EventAttributes.fromMap(Map<String, dynamic> map) {
    return EventAttributes(
      price: (map['price'] as num).toDouble(),
      smoking: RestrictionEnum.values[map['smoking'] as int],
      alcohol: RestrictionEnum.values[map['alcohol'] as int],
      isPublic: map['isPublic'] as bool,
    );
  }

  @override
  List<Object?> get props => [price, smoking, alcohol, isPublic];

  Map<String, dynamic> toMap() {
    return {
      'price': price,
      'smoking': smoking.index,
      'alcohol': alcohol.index,
      'isPublic': isPublic,
    };
  }

  final double price;
  final RestrictionEnum smoking;
  final RestrictionEnum alcohol;
  final bool isPublic;
}

class EventMetadata extends Equatable {
  const EventMetadata({
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventMetadata.fromMap(Map<String, dynamic> map) {
    return EventMetadata(
      createdAt: map['createdAt'] as DateTime,
      updatedAt: map['updatedAt'] as DateTime,
    );
  }

  @override
  List<Object?> get props => [createdAt, updatedAt];

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  final DateTime createdAt;
  final DateTime updatedAt;
}
