import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';

/// Place arama sonucu modeli
class Place {
  Place({
    required this.id,
    required this.displayAddress,
    required this.adresss,
  });

  final String id;
  final String displayAddress; // il, ilçe formatı
  final String adresss; // tam adres

  @override
  String toString() =>
      'Place(id: $id, display: $displayAddress, addr: $adresss)';
}

abstract class MapRepository {
  /// Harita sınırları içindeki etkinlikleri getirir
  Future<List<EventEntity>> fetchEventsInBounds({
    required dynamic bounds,
    int precision = 7,
  });

  /// Lokal index'i temizler
  void clearLocalIndex();

  /// Mapbox place ID'den koordinat alır
  Future<Geolocation?> getPlaceLocation(
    String placeId,
    String sessionToken,
  );

  /// Metin araması ile yer önerileri getirir
  Future<List<Place>> searchPlaces(
    String query,
    String sessionToken,
    Geolocation? proximity,
  );

  /// Koordinattan ters geocoding yapar (full address + display address)
  Future<Place?> geocodeLocation(Geolocation location);
}
