import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/core/constants/Configs/app_config.dart';

/// This provider holds the progress of the current user in each category.
/// The progress is represented as a map where the key is the category name
///  Value is the number of completed verified events in that category.
Provider<Map<String, int>> currentUserProgressProvider =
    Provider<Map<String, int>>((ref) {
      final categories = AppConfig.categories;

      //! this will be replaced with actual data from the backend in the future.
      final progress = <String, int>{};
      for (final category in categories.keys) {
        progress[category] = 0;
      }

      return progress;
    });
