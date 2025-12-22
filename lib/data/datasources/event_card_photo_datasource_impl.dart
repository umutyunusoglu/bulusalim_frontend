import 'package:bulusalim/domain/datasources/event_card_photos_datasource.dart';
import 'package:bulusalim/domain/entities/hobby/hobby_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventCardPhotosDatasourceImpl implements EventCardPhotosDatasource {
  EventCardPhotosDatasourceImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<Map<HobbyEntity, List<String>>> getAllEventCardPhotos() async {
    final snapshot = await _firestore.collection('event_card_photos').get();
    final eventCardPhotos = <HobbyEntity, List<String>>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final hobbyData = data['hobby'] as String;
      final photoUrls = (data['photoUrls'] as List<dynamic>).cast<String>();

      final hobbyEntity = HobbyEntity(name: hobbyData);

      eventCardPhotos[hobbyEntity] = photoUrls;
    }
    return eventCardPhotos;
  }

  @override
  Future<Map<HobbyEntity, List<String>>> getEventCardPhotosByHobbies(
    List<HobbyEntity> hobbies,
  ) async {
    final snapshot = await _firestore
        .collection('event_card_photos')
        .where(
          'hobby',
          whereIn: hobbies.map((hobby) => hobby.name).toList(),
        )
        .get();

    final eventCardPhotos = <HobbyEntity, List<String>>{};
    final hobbyNamesSet = hobbies.map((hobby) => hobby.name).toSet();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final hobbyData = data['hobby'] as String;

      if (hobbyNamesSet.contains(hobbyData)) {
        final photoUrls = (data['photoUrls'] as List<dynamic>).cast<String>();
        final hobbyEntity = HobbyEntity(name: hobbyData);
        eventCardPhotos[hobbyEntity] = photoUrls;
      }
    }
    return eventCardPhotos;
  }
}
