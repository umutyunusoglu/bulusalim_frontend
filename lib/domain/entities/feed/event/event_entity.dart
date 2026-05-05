import 'package:equatable/equatable.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/core/utils/types/enums/event_role_enum.dart';
import 'package:outnest/core/utils/types/enums/event_status_enum.dart';
import 'package:outnest/core/utils/types/enums/feed_entity_type_enum.dart';
import 'package:outnest/core/utils/types/enums/visibility_enum.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/event/event_community_data.dart';
import 'package:outnest/domain/entities/feed/feed_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';

class EventEntity extends FeedEntity with EquatableMixin {
  EventEntity({
    required this.eventID,
    required this.name,
    required this.city,
    required this.hobbies,
    required this.creator,
    required this.capacity,
    required this.participants,
    required this.requestPool,
    required this.status,
    required this.rejectedUsers,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.displayAddress,
    required this.address,
    required this.participantCount,
    required this.isLocked,
    required this.geohash,
    required this.visibility,
    required this.showOnMap,
    required this.accountType,
    this.visibilityGroupID,
    this.currentUserStatus,
    this.currentUserRole,
    this.communityData,
  }) : super(feedType: FeedEntityTypeEnum.event, id: eventID);

  EventEntity copyWith({
    String? eventID,
    String? name,
    String? city,
    List<String>? hobbies,
    EventStatusEnum? status,
    EventParticipantEntity? creator,
    int? capacity,
    List<CompactUserEntity>? participants,
    List<CompactUserEntity>? requestPool,
    List<CompactUserEntity>? rejectedUsers,
    DateTime? startTime,
    DateTime? endTime,
    Geolocation? location,
    String? displayAddress,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? myStatus,
    String? myRole,
    int? participantCount,
    bool? isLocked,
    String? geohash,
    VisibilityEnum? visibility,
    String? visibilityGroupID,
    bool? showOnMap,
    AccountType? accountType,
    EventCommunityData? communityData,
  }) {
    return EventEntity(
      eventID: eventID ?? this.eventID,
      name: name ?? this.name,
      city: city ?? this.city,
      hobbies: hobbies ?? this.hobbies,
      creator: creator ?? this.creator,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      requestPool: requestPool ?? this.requestPool,
      rejectedUsers: rejectedUsers ?? this.rejectedUsers,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      displayAddress: displayAddress ?? this.displayAddress,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentUserStatus: myStatus ?? currentUserStatus,
      currentUserRole: myRole ?? currentUserRole,
      participantCount: participantCount ?? this.participantCount,
      isLocked: isLocked ?? this.isLocked,
      geohash: geohash ?? this.geohash,
      visibility: visibility ?? this.visibility,
      visibilityGroupID: visibilityGroupID ?? this.visibilityGroupID,
      showOnMap: showOnMap ?? this.showOnMap,
      accountType: accountType ?? this.accountType,
      communityData: communityData ?? this.communityData,
    );
  }

  @override
  DateTime get sortDate => createdAt;

  final String? currentUserStatus;
  final String? currentUserRole;
  final int participantCount;
  final String eventID;
  final String name;
  final String? city;
  final List<String> hobbies;
  final EventStatusEnum status;
  final EventParticipantEntity creator;
  final int capacity;
  final List<CompactUserEntity> participants;
  final List<CompactUserEntity> requestPool;
  final List<CompactUserEntity> rejectedUsers;
  final DateTime startTime;
  final DateTime? endTime;
  final Geolocation? location;
  final String displayAddress;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocked;
  final String geohash;
  final VisibilityEnum visibility;
  final String? visibilityGroupID;
  final bool showOnMap;
  final AccountType accountType;
  final EventCommunityData? communityData;

  @override
  List<Object?> get props => [
    eventID,
    name,
    hobbies,
    creator,
    capacity,
    participants,
    requestPool,
    rejectedUsers,
    startTime,
    endTime,
    location,
    displayAddress,
    address,
    updatedAt,
    status,
    communityData,
  ];
}

class EventParticipantEntity extends Equatable {
  const EventParticipantEntity({
    required this.userID,
    required this.username,
    required this.profileImageUrl,
    required this.role,
    required this.eventScore,
    required this.university,
    this.accountType,
  });

  factory EventParticipantEntity.fromMap(Map<String, dynamic> map) {
    return EventParticipantEntity(
      userID: map['userID'] as Identifier,
      username: map['username'] as String? ?? '',
      profileImageUrl: map['profileImageUrl'] as String? ?? '',
      role: EventRoleEnum.fromString(map['role'] as String? ?? ''),
      eventScore: 0.0,
      university: map['university'] as String?,
      accountType: AccountType.fromString(
        map['accountType'] as String? ?? 'personal',
      ),
    );
  }

  EventParticipantEntity copyWith({
    Identifier? userID,
    String? username,
    String? profileImageUrl,
    EventRoleEnum? role,
    double? eventScore,
    String? university,
    AccountType? accountType,
  }) {
    return EventParticipantEntity(
      userID: userID ?? this.userID,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      eventScore: eventScore ?? this.eventScore,
      university: university ?? this.university,
      accountType: accountType ?? this.accountType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'role': role.toString(),
      'eventScore': eventScore,
      'university': university,
      'accountType': accountType?.toString(),
    };
  }

  @override
  List<Object?> get props => [userID];

  final Identifier userID;
  final String username;
  final String profileImageUrl;
  final EventRoleEnum role;
  final double eventScore;
  final String? university;
  final AccountType? accountType;
}
