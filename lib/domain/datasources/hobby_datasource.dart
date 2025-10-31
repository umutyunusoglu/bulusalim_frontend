import 'package:bulusalim/domain/entities/hobby/index.dart';

abstract class HobbyDataSource {
  Future<List<HobbyEntity>> getHobbies();
}
