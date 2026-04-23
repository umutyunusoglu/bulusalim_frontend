import 'package:equatable/equatable.dart';

sealed class DumpPage extends Equatable {
  // sıralama
  const DumpPage({required this.id, required this.order});
  final String id;
  final int order;
}

class DumpStatsPageEntity extends DumpPage {
  const DumpStatsPageEntity({
    required super.id,
    required super.order,
    required this.bgImageUrl,
    required this.eventCount,
    required this.eventHours,
    required this.userCount,
  });
  final String bgImageUrl;
  final int eventCount;
  final double eventHours;
  final int userCount;

  @override
  List<Object?> get props => [
    id,
    order,
    bgImageUrl,
    eventCount,
    eventHours,
    userCount,
  ];
}

class DumpMostPopularPostPageEntity extends DumpPage {
  const DumpMostPopularPostPageEntity({
    required super.id,
    required super.order,
    required this.bgImageUrl,
    required this.emoteCounts,
  });

  final String bgImageUrl;
  final Map<String, int> emoteCounts;

  @override
  List<Object?> get props => [id, order, bgImageUrl, emoteCounts];
}

class DumpMostlyDoneEventPageEntity extends DumpPage {
  const DumpMostlyDoneEventPageEntity({
    required super.id,
    required super.order,
    required this.bgImageUrl,
    required this.category,
    required this.eventCount,
  });
  final String bgImageUrl;
  final String category;
  final int eventCount;

  @override
  List<Object?> get props => [id, order, bgImageUrl, category, eventCount];
}

class DumpGridPageEntity extends DumpPage {
  const DumpGridPageEntity({
    required super.id,
    required super.order,
    required this.imageUrls,
    required this.dumpWidth,
    required this.dumpHeight,
    required this.permutedIndices,
  });
  final List<String> imageUrls;
  final int dumpWidth;
  final int dumpHeight;
  final List<int> permutedIndices;

  List<List<String>> get eventPhotoUrlMatrix {
    final matrix = List<List<String>>.generate(
      dumpHeight,
      (_) => List.filled(dumpWidth, ''),
    );

    for (var i = 0; i < imageUrls.length; i++) {
      final permutedIndex = permutedIndices[i];
      final row = permutedIndex ~/ dumpWidth;
      final col = permutedIndex % dumpWidth;
      matrix[row][col] = imageUrls[i];
    }

    return matrix;
  }

  @override
  List<Object?> get props => [
    id,
    order,
    imageUrls,
    dumpWidth,
    dumpHeight,
    permutedIndices,
  ];
}
