import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/data/models/organization/organization_model.dart';
import 'package:outnest/domain/datasources/university_datasource.dart';
import 'package:outnest/domain/entities/organization/organization_entity.dart';
import 'package:outnest/domain/services/remote_config_service.dart';

class UniversityDataSourceImpl implements UniversityDatasource {
  UniversityDataSourceImpl({required this.logger});

  final LoggingService logger;
  final String _assetPath = 'assets/data/universities.json';

  // Bellekte tutulacak liste
  List<OrganizationEntity> _cachedUniversities = [];
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      logger.debug('Caching universities from local asset...');
      final remoteConfig = getIt<RemoteConfigService>();

      var response = '';
      try {
        logger.debug('Attempting to fetch universities from Remote Config...');
        response = await remoteConfig.getValue<String>('universities');
      } catch (e) {
        logger.error('Remote Config fetch failed, falling back to asset: $e');
        response = await rootBundle.loadString(_assetPath);
      }

      final data = json.decode(response) as List<dynamic>;

      _cachedUniversities = data.map((item) {
        final map = item as Map<String, dynamic>;
        return OrganizationModel.fromMap({
          'name': map['name'],
          'mailExtension': (map['domains'] as List).cast<String>(),
          'similarDomains':
              (map['similar_domains'] as List?)?.cast<String>() ?? const [],
        }).toEntity();
      }).toList();

      _isInitialized = true;
      logger.debug(
        'Successfully cached ${_cachedUniversities.length} universities.',
      );
    } catch (e) {
      logger.error('University caching failed: $e');
    }
  }

  // Yardımcı metod: Eğer cache boşsa doldurulmasını bekler
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  @override
  Future<List<OrganizationEntity>> getAllUniversitiesInCountry({
    String? universityName,
    String? country,
  }) async {
    await _ensureInitialized();

    return _cachedUniversities.where((uni) {
      // JSON'ınızda ülke bilgisi varsa burada filtreleyebilirsiniz.
      // Hipolabs formatında 'country' alanı bulunur.
      final matchesName =
          universityName == null ||
          uni.name.toLowerCase().contains(universityName.toLowerCase());

      return matchesName;
    }).toList();
  }

  @override
  Future<List<String>> getUniversityOfMail(
    String email,
    String? country,
  ) async {
    if (!email.contains('@')) return [];
    final emailDomain = email.split('@').last.toLowerCase().trim();

    await _ensureInitialized();

    // RAM üzerindeki liste üzerinden anında filtreleme yapar
    final matches = _cachedUniversities.where((uni) {
      return uni.mailExtension.any(
        (domain) => domain.toLowerCase() == emailDomain,
      );
    }).toList();

    return matches.map((e) => e.name).toList();
  }

  @override
  Future<List<String>> getUniversityMailExtensions({
    String? universityName,
    String? country,
  }) async {
    final unis = await getAllUniversitiesInCountry(
      universityName: universityName,
      country: country,
    );
    return unis.isNotEmpty ? unis.first.mailExtension : [];
  }

  @override
  Future<List<UniversitySuggestion>> findSuggestionsForMail(
    String email,
    String? country,
  ) async {
    logger.debug('Finding suggestions for email: $email');
    if (!email.contains('@')) return const [];

    final parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty) return const [];

    final localPart = parts[0];
    final emailDomain = parts[1].toLowerCase().trim();

    await _ensureInitialized();

    // Zaten geçerli bir domain ise öneri verme
    final alreadyValid = _cachedUniversities.any(
      (uni) => uni.mailExtension.any(
        (d) => d.toLowerCase() == emailDomain,
      ),
    );
    if (alreadyValid) return const [];

    final suggestions = <UniversitySuggestion>[];

    for (final uni in _cachedUniversities) {
      final hitsSimilar = uni.similarDomains.any(
        (d) => d.toLowerCase() == emailDomain,
      );
      if (hitsSimilar && uni.mailExtension.isNotEmpty) {
        final correctDomain = uni.mailExtension.first;
        suggestions.add(
          UniversitySuggestion(
            universityName: uni.name,
            suggestedEmail: '$localPart@$correctDomain',
            originalDomain: emailDomain,
            suggestedDomain: correctDomain,
          ),
        );
      }
    }

    return suggestions;
  }
}
