import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';

abstract class MapRepository {
  Future<List<EventEntity>> fetchEventsInBounds({
    required dynamic bounds,
    required int precision,
  });

  Future<List<Place>> searchPlaces(String query, String sessionToken);
  Future<Geolocation?> getPlaceLocation(String placeId, String sessionToken);

  void clearLocalIndex();
}

class Place {
  Place({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
