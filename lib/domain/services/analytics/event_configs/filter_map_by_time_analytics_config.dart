import 'package:flutter/material.dart';
import 'package:outnest/domain/services/analytics/analytics_constants.dart';

class FilterMapByTimeAnalyticsConfig {
  FilterMapByTimeAnalyticsConfig({
    required this.time,
  });

  Map<String, Object> toMap() {
    return {
      AnalyticsParams.value: time,
    };
  }

  final DateTimeRange time;
}
