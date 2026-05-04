import 'package:outnest/domain/entities/dump/dump_page_entity.dart';

sealed class DumpPageModel {
  const DumpPageModel({required this.id, required this.order});

  final String id;
  final int order;

  static DumpPageModel? fromFirestore(Map<String, dynamic> doc) {
    final type = doc['type'] as String?;

    return switch (type) {
      'stats' => DumpStatsPageModel.fromFirestore(doc),
      'most_popular_post' => DumpMostPopularPostPageModel.fromFirestore(doc),
      'mostly_done_event' => DumpMostlyDoneEventPageModel.fromFirestore(doc),
      'grid' => DumpGridPageModel.fromFirestore(doc),
      _ => null,
    };
  }

  static DumpPageModel fromEntity(DumpPage entity) {
    return switch (entity) {
      DumpStatsPageEntity() => DumpStatsPageModel.fromEntity(entity),
      DumpMostPopularPostPageEntity() =>
        DumpMostPopularPostPageModel.fromEntity(entity),
      DumpMostlyDoneEventPageEntity() =>
        DumpMostlyDoneEventPageModel.fromEntity(entity),
      DumpGridPageEntity() => DumpGridPageModel.fromEntity(entity),
    };
  }

  DumpPage toEntity();
  Map<String, dynamic> toFirestore();
}

// ---------------------------------------------------------------------------

class DumpStatsPageModel extends DumpPageModel {
  const DumpStatsPageModel({
    required super.id,
    required super.order,
    required this.bgImageUrl,
    required this.eventCount,
    required this.eventHours,
    required this.userCount,
  });

  factory DumpStatsPageModel.fromFirestore(Map<String, dynamic> doc) {
    return DumpStatsPageModel(
      id: doc['id'] as String,
      order: doc['order'] as int,
      bgImageUrl: doc['bgImageUrl'] as String,
      eventCount: doc['eventCount'] as int,
      eventHours: (doc['eventHours'] as num).toDouble(),
      userCount: doc['userCount'] as int,
    );
  }

  factory DumpStatsPageModel.fromEntity(DumpStatsPageEntity entity) {
    return DumpStatsPageModel(
      id: entity.id,
      order: entity.order,
      bgImageUrl: entity.bgImageUrl,
      eventCount: entity.eventCount,
      eventHours: entity.eventHours,
      userCount: entity.userCount,
    );
  }

  @override
  DumpStatsPageEntity toEntity() {
    return DumpStatsPageEntity(
      id: id,
      order: order,
      bgImageUrl: bgImageUrl,
      eventCount: eventCount,
      eventHours: eventHours,
      userCount: userCount,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'type': 'stats',
      'id': id,
      'order': order,
      'bgImageUrl': bgImageUrl,
      'eventCount': eventCount,
      'eventHours': eventHours,
      'userCount': userCount,
    };
  }

  final String bgImageUrl;
  final int eventCount;
  final double eventHours;
  final int userCount;
}

// ---------------------------------------------------------------------------

class DumpMostPopularPostPageModel extends DumpPageModel {
  const DumpMostPopularPostPageModel({
    required super.id,
    required super.order,
    required this.bgImageUrl,
    required this.emoteCounts,
  });

  factory DumpMostPopularPostPageModel.fromFirestore(
    Map<String, dynamic> doc,
  ) {
    return DumpMostPopularPostPageModel(
      id: doc['id'] as String,
      order: doc['order'] as int,
      bgImageUrl: doc['bgImageUrl'] as String,
      emoteCounts: Map<String, int>.from(doc['emoteCounts'] as Map),
    );
  }

  factory DumpMostPopularPostPageModel.fromEntity(
    DumpMostPopularPostPageEntity entity,
  ) {
    return DumpMostPopularPostPageModel(
      id: entity.id,
      order: entity.order,
      bgImageUrl: entity.bgImageUrl,
      emoteCounts: entity.emoteCounts,
    );
  }

  @override
  DumpMostPopularPostPageEntity toEntity() {
    return DumpMostPopularPostPageEntity(
      id: id,
      order: order,
      bgImageUrl: bgImageUrl,
      emoteCounts: emoteCounts,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'type': 'most_popular_post',
      'id': id,
      'order': order,
      'bgImageUrl': bgImageUrl,
      'emoteCounts': emoteCounts,
    };
  }

  final String bgImageUrl;
  final Map<String, int> emoteCounts;
}

// ---------------------------------------------------------------------------

class DumpMostlyDoneEventPageModel extends DumpPageModel {
  const DumpMostlyDoneEventPageModel({
    required super.id,
    required super.order,
    required this.bgImageUrl,
    required this.category,
    required this.eventCount,
  });

  factory DumpMostlyDoneEventPageModel.fromFirestore(
    Map<String, dynamic> doc,
  ) {
    return DumpMostlyDoneEventPageModel(
      id: doc['id'] as String,
      order: doc['order'] as int,
      bgImageUrl: doc['bgImageUrl'] as String,
      category: doc['category'] as String,
      eventCount: doc['eventCount'] as int,
    );
  }

  factory DumpMostlyDoneEventPageModel.fromEntity(
    DumpMostlyDoneEventPageEntity entity,
  ) {
    return DumpMostlyDoneEventPageModel(
      id: entity.id,
      order: entity.order,
      bgImageUrl: entity.bgImageUrl,
      category: entity.category,
      eventCount: entity.eventCount,
    );
  }

  @override
  DumpMostlyDoneEventPageEntity toEntity() {
    return DumpMostlyDoneEventPageEntity(
      id: id,
      order: order,
      bgImageUrl: bgImageUrl,
      category: category,
      eventCount: eventCount,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'type': 'mostly_done_event',
      'id': id,
      'order': order,
      'bgImageUrl': bgImageUrl,
      'category': category,
      'eventCount': eventCount,
    };
  }

  final String bgImageUrl;
  final String category;
  final int eventCount;
}

// ---------------------------------------------------------------------------

class DumpGridPageModel extends DumpPageModel {
  const DumpGridPageModel({
    required super.id,
    required super.order,
    required this.imageUrls,
    required this.dumpWidth,
    required this.dumpHeight,
    required this.permutedIndices,
  });

  factory DumpGridPageModel.fromFirestore(Map<String, dynamic> doc) {
    return DumpGridPageModel(
      id: doc['id'] as String,
      order: doc['order'] as int,
      imageUrls: List<String>.from(doc['imageUrls'] as List),
      dumpWidth: doc['dumpWidth'] as int,
      dumpHeight: doc['dumpHeight'] as int,
      permutedIndices: List<int>.from(doc['permutedIndices'] as List),
    );
  }

  factory DumpGridPageModel.fromEntity(DumpGridPageEntity entity) {
    return DumpGridPageModel(
      id: entity.id,
      order: entity.order,
      imageUrls: entity.imageUrls,
      dumpWidth: entity.dumpWidth,
      dumpHeight: entity.dumpHeight,
      permutedIndices: entity.permutedIndices,
    );
  }

  @override
  DumpGridPageEntity toEntity() {
    return DumpGridPageEntity(
      id: id,
      order: order,
      imageUrls: imageUrls,
      dumpWidth: dumpWidth,
      dumpHeight: dumpHeight,
      permutedIndices: permutedIndices,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'type': 'grid',
      'id': id,
      'order': order,
      'imageUrls': imageUrls,
      'dumpWidth': dumpWidth,
      'dumpHeight': dumpHeight,
      'permutedIndices': permutedIndices,
    };
  }

  final List<String> imageUrls;
  final int dumpWidth;
  final int dumpHeight;
  final List<int> permutedIndices;
}
