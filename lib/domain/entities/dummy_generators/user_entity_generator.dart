import 'package:bulusalim/core/utils/types/enums/event_role_enum.dart';
import 'package:bulusalim/core/utils/types/enums/gender_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:bulusalim/domain/entities/user/user_event_entity.dart';
import 'package:bulusalim/domain/entities/user/user_hobby_entity.dart';
import 'package:faker/faker.dart';
import 'package:uuid/uuid.dart';

class UserEntityGenerator {
  static final _faker = Faker();
  static const _uuid = Uuid();

  static const int minYear = 1950;
  static const int currentYear = 2025;

  static UserEntity generateRandomUser() {
    final creationTime = faker.date.dateTime(minYear: 1950, maxYear: 2025);

    final updateTime = faker.date.dateTimeBetween(
      creationTime,
      DateTime.now(),
    );

    final lastActiveTime = faker.date.dateTimeBetween(
      updateTime,
      DateTime.now(),
    );
    return UserEntity(
      id: _uuid.v4(),
      username: _faker.internet.userName(),
      email: _faker.internet.email(),
      birthDate: _faker.date.dateTime(minYear: 1950, maxYear: 2005),
      gender: _faker.randomGenerator.element(GenderEnum.values),
      organization: _faker.company.name(),
      profilePhotoUrls: List.generate(
        _faker.randomGenerator.integer(3, min: 1),
        (index) => _faker.internet.httpsUrl(),
      ),
      bio: _faker.lorem.sentence(),
      metadata: UserMetadata(
        createdAt: creationTime,
        updatedAt: updateTime,
        lastActiveAt: lastActiveTime,
      ),
      permissions: UserPermissions(
        locationEnabled: _faker.randomGenerator.boolean(),
        notificationsEnabled: _faker.randomGenerator.boolean(),
      ),
    );
  }

  static UserHobbyEntity generateRandomUserHobby() {
    return UserHobbyEntity(
      hobby: HobbyEntity(name: _faker.food.dish()),
      level: _faker.randomGenerator.integer(10, min: 1),
      eventsJoined: _faker.randomGenerator.integer(50),
      rating: _faker.randomGenerator.decimal(scale: 5, min: 1),
    );
  }

  static UserEventEntity generateRandomUserEvent() {
    return UserEventEntity(
      eventId: _uuid.v4(),
      eventDate: _faker.date.dateTime(minYear: 2024, maxYear: 2026),
      role: _faker.randomGenerator.element(EventRoleEnum.values),
    );
  }
}
