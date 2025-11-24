import 'package:bulusalim/core/utils/types/enums/event_role_enum.dart';
import 'package:bulusalim/core/utils/types/enums/restriction_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/feed/feed_entity.dart';
import 'package:equatable/equatable.dart';

class EventEntity extends FeedEntity with EquatableMixin {
  EventEntity({
    required this.eventID,
    required this.name,
    required this.hobbies,
    required this.creator,
    required this.capacity,
    required this.participants,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.attributes,
    required this.createdAt,
    required this.updatedAt,
    this.info,
  }) : super(feedType: FeedEntityType.event, id: eventID);

  EventEntity copyWith({
    String? eventID,
    String? name,
    String? info,
    List<String>? hobbies,
    EventParticipantEntity? creator,
    int? capacity,
    List<EventParticipantEntity>? participants,
    DateTime? startTime,
    DateTime? endTime,
    Geolocation? location,
    EventAttributes? attributes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventEntity(
      eventID: eventID ?? this.eventID,
      name: name ?? this.name,
      info: info ?? this.info,
      hobbies: hobbies ?? this.hobbies,
      creator: creator ?? this.creator,
      capacity: capacity ?? this.capacity,
      participants: participants ?? this.participants,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      attributes: attributes ?? this.attributes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  final String eventID;
  final String name;
  final String? info;
  final List<String> hobbies;
  final EventParticipantEntity creator;
  final int capacity;
  final List<EventParticipantEntity> participants;
  final DateTime startTime;
  final DateTime endTime;
  final Geolocation location;
  final EventAttributes attributes;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [eventID];
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

class EventParticipantEntity extends Equatable {
  const EventParticipantEntity({
    required this.userID,
    required this.username,
    required this.profileImageUrl,
    required this.role,
    required this.eventScore,
  });

  EventParticipantEntity copyWith({
    Identifier? userID,
    String? username,
    String? profileImageUrl,
    EventRoleEnum? role,
    double? eventScore,
  }) {
    return EventParticipantEntity(
      userID: userID ?? this.userID,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      eventScore: eventScore ?? this.eventScore,
    );
  }

  factory EventParticipantEntity.fromMap(Map<String, dynamic> map) {
    return EventParticipantEntity(
      userID: map['userID'] as Identifier,
      username: map['username'] as String,
      profileImageUrl: map['profileImageUrl'] as String,
      role: EventRoleEnum.fromString(map['role'] as String),
      eventScore: (map['eventScore'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'role': role.index,
      'eventScore': eventScore,
    };
  }

  @override
  List<Object?> get props => [userID, role, eventScore];

  final Identifier userID;
  final String username;
  final String profileImageUrl;
  final EventRoleEnum role;
  final double eventScore;
}
