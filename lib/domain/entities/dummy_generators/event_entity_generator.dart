import 'package:bulusalim/core/utils/types/enums/restriction_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/event/event_entity.dart';
import 'package:bulusalim/domain/entities/event/event_messages_entity.dart';
import 'package:bulusalim/domain/entities/event/participant_entity.dart';
import 'package:bulusalim/domain/entities/event/participant_rating_entity.dart';
import 'package:faker/faker.dart';
import 'package:uuid/uuid.dart';
import 'package:bulusalim/core/utils/types/enums/event_role_enum.dart';

/*
class EventEntityGenerator {
  static final _faker = Faker();
  static const _uuid = Uuid();

  static EventEntity generateRandomEvent() {
    return EventEntity(
      eventId: _uuid.v4(),
      name: faker.lorem.sentence(),
      hobbies: hobbies,
      creator: creator,
      capacity: capacity,
      participants: participants,
      participantScores: participantScores,
      startTime: startTime,
      endTime: endTime,
      location: location,
      attributes: attributes,
      metadata: metadata,
    );
  }
}
*/
