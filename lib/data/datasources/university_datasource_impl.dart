import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/data/models/organization/organization_model.dart';
import 'package:bulusalim/domain/datasources/university_datasource.dart';
import 'package:bulusalim/domain/entities/organization/organization_entity.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UniversityDataSourceImpl implements UniversityDatasource {
  UniversityDataSourceImpl({required this.httpClient, required this.logger});

  final LoggingService logger;
  final http.Client httpClient;

  final apiRootUrl = 'http://universities.hipolabs.com/search';

  @override
  Future<List<OrganizationEntity>> getAllUniversities({
    String? universityName,
    String? country,
  }) async {
    final queryParameters = <String, String>{};
    if (country != null && country.isNotEmpty) {
      queryParameters['country'] = country;
    }
    if (universityName != null && universityName.isNotEmpty) {
      queryParameters['name'] = universityName;
    }

    final uri = Uri.parse(apiRootUrl).replace(queryParameters: queryParameters);
    logger.debug('Fetching universities from $uri');
    final response = await httpClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load universities: ${response.reasonPhrase}');
    }

    final data = json.decode(response.body) as List<dynamic>;

    final universities = <OrganizationEntity>[];
    logger.debug('Fetched $data universities from API.');
    for (final item in data) {
      final map = item as Map<String, dynamic>;
      final name = map['name'] as String;
      final domains = (map['domains'] as List).cast<String>();

      final organizationModel = OrganizationModel.fromMap({
        'name': name,
        'mailExtension': domains, // Modelin ne beklediğine göre düzelt
      });

      universities.add(organizationModel.toEntity());
    }

    return universities;
  }

  @override
  Future<List<String>> getUniversityMailExtensions({
    String? universityName,
    String? country,
  }) {
    return getAllUniversities(
      country: country,
      universityName: universityName,
    ).then((universities) {
      if (universities.isNotEmpty) {
        return universities.first.mailExtension.isNotEmpty
            ? universities.first.mailExtension
            : [];
      }
      return [];
    });
  }
}
