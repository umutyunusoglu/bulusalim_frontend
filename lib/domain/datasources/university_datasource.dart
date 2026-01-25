import 'package:bulusalim/domain/entities/organization/organization_entity.dart';

abstract class UniversityDatasource {
  Future<List<OrganizationEntity>> getAllUniversitiesInCountry({
    String? country,
    String? universityName,
  });

  Future<List<String>> getUniversityMailExtensions({
    String? universityName,
    String? country,
  });

  Future<List<String>> getUniversityOfMail(String email, String? country);

  void initialize();
}
