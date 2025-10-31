import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/organization/organization_entity.dart';

class OrganizationModel extends Model<OrganizationEntity> {
  OrganizationModel({required this.name, required this.mailExtension});

  factory OrganizationModel.fromMap(Map<String, dynamic> map) {
    return OrganizationModel(
      name: map['name'] as String,
      mailExtension: List<String>.from(map['mailExtension'] as List),
    );
  }

  factory OrganizationModel.fromEntity(OrganizationEntity entity) {
    return OrganizationModel(
      name: entity.name,
      mailExtension: entity.mailExtension,
    );
  }

  @override
  OrganizationEntity toEntity() {
    return OrganizationEntity(
      name: name,
      mailExtension: mailExtension,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mailExtension': mailExtension,
    };
  }

  @override
  Map<String, dynamic> toFirestore() {
    // TODO: implement toFirestore
    throw UnimplementedError();
  }

  final String name;
  final List<String> mailExtension;
}
