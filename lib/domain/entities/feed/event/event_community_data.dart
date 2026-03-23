import 'package:equatable/equatable.dart';

class EventCommunityData extends Equatable {
  const EventCommunityData({
    this.description,
    this.rules,
    this.venueInfo,
    this.link,
    this.maxParticipants,
    this.requiresDocument,
    this.coverImageUrl,
  });

  factory EventCommunityData.fromMap(Map<String, dynamic> map) {
    return EventCommunityData(
      description: map['communityDescription'] as String?,
      rules: map['communityRules'] as String?,
      venueInfo: map['communityVenueInfo'] as String?,
      link: map['communityLink'] as String?,
      maxParticipants: map['communityMaxParticipants'] as int?,
      requiresDocument: map['communityRequiresDocument'] as bool?,
      coverImageUrl: map['communityCoverImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'communityDescription': description,
      'communityRules': rules,
      'communityVenueInfo': venueInfo,
      'communityLink': link,
      'communityMaxParticipants': maxParticipants,
      'communityRequiresDocument': requiresDocument,
      'communityCoverImageUrl': coverImageUrl,
    };
  }

  EventCommunityData copyWith({
    String? description,
    String? rules,
    String? venueInfo,
    String? link,
    int? maxParticipants,
    bool? requiresDocument,
    String? coverImageUrl,
  }) {
    return EventCommunityData(
      description: description ?? this.description,
      rules: rules ?? this.rules,
      venueInfo: venueInfo ?? this.venueInfo,
      link: link ?? this.link,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      requiresDocument: requiresDocument ?? this.requiresDocument,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }

  final String? description;
  final String? rules;
  final String? venueInfo;
  final String? link;
  final int? maxParticipants;
  final bool? requiresDocument;
  final String? coverImageUrl;

  @override
  List<Object?> get props => [
    description,
    rules,
    venueInfo,
    link,
    maxParticipants,
    requiresDocument,
    coverImageUrl,
  ];
}
