import 'package:bulusalim/domain/entities/hobby/index.dart';

abstract class EventCardPhotosDatasource {
  Future<Map<HobbyEntity, List<String>>> getAllEventCardPhotos();
  Future<Map<HobbyEntity, List<String>>> getEventCardPhotosByHobbies(
    List<HobbyEntity> hobbies,
  );
}
