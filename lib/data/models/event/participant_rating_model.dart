import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/feed/event/participant_rating_entity.dart';

class ParticipantRatingModel implements Model<ParticipantRatingEntity> {
  ParticipantRatingModel({
    required this.eventID,
    required this.raterID,
    required this.rateeID,
    required this.rating,
  });

  factory ParticipantRatingModel.fromEntity(ParticipantRatingEntity entity) {
    return ParticipantRatingModel(
      eventID: entity.eventID,
      raterID: entity.raterID,
      rateeID: entity.rateeID,
      rating: entity.rating,
    );
  }

  factory ParticipantRatingModel.fromFirestore(Map<String, dynamic> firestore) {
    return ParticipantRatingModel(
      eventID: firestore['eventID'] as Identifier,
      raterID: firestore['raterID'] as Identifier,
      rateeID: firestore['rateeID'] as Identifier,
      rating: (firestore['rating'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'eventID': eventID,
      'raterID': raterID,
      'rateeID': rateeID,
      'rating': rating,
    };
  }

  @override
  ParticipantRatingEntity toEntity() {
    return ParticipantRatingEntity(
      eventID: eventID,
      raterID: raterID,
      rateeID: rateeID,
      rating: rating,
    );
  }

  final Identifier eventID;
  final Identifier raterID;
  final Identifier rateeID;
  final double rating;
}
