import 'package:bulusalim/core/utils/types/types.dart';
import 'package:equatable/equatable.dart';

class ParticipantRatingEntity extends Equatable {
  const ParticipantRatingEntity({
    required this.eventID,
    required this.raterID,
    required this.rateeID,
    required this.rating,
  });

  @override
  List<Object?> get props => [eventID, raterID, rateeID, rating];

  ParticipantRatingEntity copyWith({
    Identifier? eventID,
    Identifier? raterID,
    Identifier? rateeID,
    double? rating,
  }) {
    return ParticipantRatingEntity(
      eventID: eventID ?? this.eventID,
      raterID: raterID ?? this.raterID,
      rateeID: rateeID ?? this.rateeID,
      rating: rating ?? this.rating,
    );
  }

  final Identifier eventID;
  final Identifier raterID;
  final Identifier rateeID;
  final double rating;
}
