import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:faker/faker.dart';
import 'package:uuid/uuid.dart';

class DummyHobbyGenerator {
  static final _faker = Faker();
  static const _uuid = Uuid();

  static final List<HobbyEntity> hobbyCategories = [];

  static final List<HobbyEntity> hobbies = [
    HobbyEntity(name: "basketball"),
    HobbyEntity(name: "football"),

    HobbyEntity(name: "painting"),
  ];

  static HobbyEntity generateRandomHobby() {
    return HobbyEntity(
      name: _faker.food.dish(),
    );
  }
}
