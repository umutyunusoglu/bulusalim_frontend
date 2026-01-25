import 'dart:convert';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/data/models/organization/organization_model.dart';
import 'package:bulusalim/domain/datasources/university_datasource.dart';
import 'package:bulusalim/domain/entities/organization/organization_entity.dart';
import 'package:http/http.dart' as http;

class UniversityDataSourceImpl implements UniversityDatasource {
  UniversityDataSourceImpl({required this.httpClient, required this.logger});

  final LoggingService logger;
  final http.Client httpClient;

  final apiRootUrl = 'http://universities.hipolabs.com/search';

  @override
  Future<List<OrganizationEntity>> getAllUniversitiesInCountry({
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
    return getAllUniversitiesInCountry(
      country: country,
      universityName: universityName,
    ).then((universities) {
      if (universities.isNotEmpty) {
        final university = universities.first;
        return university.mailExtension;
      }
      return [];
    });
  }

  @override
  Future<List<String>> getUniversityOfMail(
    String email,
    String? country,
  ) async {
    // 1. Email'den domain ayıklama
    if (!email.contains('@')) return [];
    final emailDomain = email.split('@').last.toLowerCase().trim();

    try {
      // 2. Belirtilen ülkedeki üniversiteleri getir
      // Performans için 'country' parametresini API'ye gönderiyoruz
      final allUniversities = await getAllUniversitiesInCountry(
        country: country ?? 'Turkey',
      );

      // 3. Domain eşleştirmesi yap
      final matchingUniversities = allUniversities.where((uni) {
        // API bazen 'domains' (List<String>) döndürür, paylaştığınız formatta ise 'domain' (String)
        // Entity içinde bu mailExtension olarak tutuluyorsa:
        return uni.mailExtension.any(
          (domain) => domain.toLowerCase() == emailDomain,
        );
      }).toList();

      // 4. Eşleşen üniversitelerin isimlerini döndür
      return matchingUniversities.map((e) => e.name).toList();
    } catch (e) {
      logger.error('Üniversite aranırken hata oluştu: $e');
      return [];
    }
  }
}
