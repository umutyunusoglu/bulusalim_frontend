import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:riverpod/misc.dart';

/// This provider holds the progress of the current user in each category.
/// The progress is represented as a map where the key is the category name
///  Value is the number of completed verified events in that category.
ProviderFamily<int, String> currentUserProgressProvider =
    ProviderFamily<int, String>((ref, category) {
      if (!AppConfig.categories.containsKey(category)) {
        throw ArgumentError('Invalid category: $category');
      }

      return 0;
    });
