import 'package:outnest/core/utils/types/geolocation/geolocation.dart';

abstract class GeocodingService {
  ({String city, String district})? getCityDistrictFromGeolocation(
    Geolocation geolocation,
  );
}
