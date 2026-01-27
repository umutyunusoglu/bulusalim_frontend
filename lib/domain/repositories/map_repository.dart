import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';

abstract class MapRepository {
  Future<List<EventEntity>> fetchEventsInBounds({
    required dynamic bounds,
    required int precision,
  });

  Future<List<Place>> searchPlaces(String query, String sessionToken);
  Future<Geolocation?> getPlaceLocation(String placeId, String sessionToken);
  Future<Place?> geocodeLocation(Geolocation location);

  void clearLocalIndex();
}

class Place {
  Place({
    required this.id,
    required this.displayAddress,
    required this.adresss,
  });

  final String id;
  final String displayAddress;
  final String adresss;
}
