import 'package:bulusalim/core/utils/types/enums/feed_entity_type_enum.dart';

abstract class FeedEntity {
  FeedEntity({
    required this.feedType,
    required this.id,
  });
  final String id;
  final FeedEntityTypeEnum feedType;
}
