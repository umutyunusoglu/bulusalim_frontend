import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';

abstract class MapRepository {
  Future<List<EventEntity>> fetchEventsInBounds({
    required dynamic bounds,
    required int precision,
  });

  void clearLocalIndex();
}
