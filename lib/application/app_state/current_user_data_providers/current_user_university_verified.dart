import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';

final Provider<bool> currentUserUniversityVerifiedProvider =
    Provider.autoDispose<bool>((ref) {
      final currentUser = ref.watch(currentUserEntityProvider).asData?.value;
      if (currentUser == null) return false;
      return currentUser.universityEmail?.isNotEmpty ?? false;
    });
