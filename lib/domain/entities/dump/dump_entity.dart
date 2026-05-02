import 'package:equatable/equatable.dart';
import 'package:outnest/domain/entities/dump/dump_page_entity.dart';

class DumpEntity extends Equatable {
  const DumpEntity({
    required this.id,
    required this.createdAt,
    required this.pages,
  });

  final String id;
  final DateTime createdAt;
  final List<DumpPage> pages;

  @override
  List<Object?> get props => [id, createdAt, pages];
}
