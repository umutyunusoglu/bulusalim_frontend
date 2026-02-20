import 'package:outnest/core/utils/types/enums/gender_enum.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class SelectGenderAnalyticsConfig {
  SelectGenderAnalyticsConfig({
    required this.value,
    required this.previousValue,
  });

  final GenderEnum? value;
  final GenderEnum? previousValue;

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.value: value?.name ?? 'null',
      AnalyticsParams.previousValue: previousValue?.name ?? 'null',
    };
  }
}
