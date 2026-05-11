import 'package:outnest/domain/entities/organization/organization_entity.dart';

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

  Future<List<UniversitySuggestion>> findSuggestionsForMail(
    String email,
    String? country,
  );

  void initialize();
}

class UniversitySuggestion {
  const UniversitySuggestion({
    required this.universityName,
    required this.suggestedEmail,
    required this.originalDomain,
    required this.suggestedDomain,
  });

  final String universityName;
  final String suggestedEmail; // örn: ali@boun.edu.tr
  final String originalDomain; // örn: bogazici.edu.tr (yanlış yazılan)
  final String suggestedDomain; // örn: boun.edu.tr (doğrusu)
}
