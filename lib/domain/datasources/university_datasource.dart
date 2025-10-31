import 'package:bulusalim/domain/entities/organization/organization_entity.dart';

abstract class UniversityDatasource {
  Future<List<OrganizationEntity>> getAllUniversities({
    String? country,
    String? universityName,
  });

  Future<List<String>> getUniversityMailExtensions({
    String? universityName,
    String? country,
  });
}
