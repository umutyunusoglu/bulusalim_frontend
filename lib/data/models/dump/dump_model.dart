import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/data/models/dump/dump_page_model.dart';
import 'package:outnest/data/models/model.dart';
import 'package:outnest/domain/entities/dump/dump_entity.dart';

class DumpModel extends Model<DumpEntity> {
  DumpModel({
    required this.id,
    required this.createdAt,
    required this.pages,
  });

  factory DumpModel.fromEntity(DumpEntity entity) {
    return DumpModel(
      id: entity.id,
      createdAt: entity.createdAt,
      pages: entity.pages.map(DumpPageModel.fromEntity).toList(),
    );
  }

  factory DumpModel.fromFirestore(Map<String, dynamic> doc) {
    final rawPages = (doc['pages'] as List<dynamic>?) ?? [];

    return DumpModel(
      id: doc['id'] as String,
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
      pages: rawPages
          .map((e) => DumpPageModel.fromFirestore(e as Map<String, dynamic>))
          .whereType<DumpPageModel>()
          .toList(),
    );
  }

  @override
  DumpEntity toEntity() {
    return DumpEntity(
      id: id,
      createdAt: createdAt,
      pages: pages.map((p) => p.toEntity()).toList(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'createdAt': createdAt,
      'pages': pages.map((p) => p.toFirestore()).toList(),
    };
  }

  final String id;
  final DateTime createdAt;
  final List<DumpPageModel> pages;
}
