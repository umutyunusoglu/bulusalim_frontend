class Geolocation {
  Geolocation({
    required this.latitude,
    required this.longitude,
  });

  factory Geolocation.fromMap(Map<dynamic, dynamic> map) {
    return Geolocation(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  final double latitude;
  final double longitude;
}
