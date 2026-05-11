import 'package:outnest/data/models/model.dart';
import 'package:outnest/domain/entities/organization/organization_entity.dart';

class OrganizationModel extends Model<OrganizationEntity> {
  OrganizationModel({
    required this.name,
    required this.mailExtension,
    this.similarDomains = const [],
  });

  factory OrganizationModel.fromMap(Map<String, dynamic> map) {
    return OrganizationModel(
      name: map['name'] as String,
      mailExtension: List<String>.from(map['mailExtension'] as List),
      similarDomains: map['similarDomains'] != null
          ? List<String>.from(map['similarDomains'] as List)
          : const [],
    );
  }

  factory OrganizationModel.fromEntity(OrganizationEntity entity) {
    return OrganizationModel(
      name: entity.name,
      mailExtension: entity.mailExtension,
      similarDomains: entity.similarDomains,
    );
  }

  @override
  OrganizationEntity toEntity() {
    return OrganizationEntity(
      name: name,
      mailExtension: mailExtension,
      similarDomains: similarDomains,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mailExtension': mailExtension,
      'similarDomains': similarDomains,
    };
  }

  @override
  Map<String, dynamic> toFirestore() {
    // TODO: implement toFirestore
    throw UnimplementedError();
  }

  final String name;
  final List<String> mailExtension;
  final List<String> similarDomains;
}
