import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/app_state/auth_state_provider.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/auth_service.dart';

final currentUserEntityProvider = StreamProvider<UserEntity?>((ref) {
  final userId = ref.watch(authStateProvider).value;
  if (userId == null) return Stream.value(null);
  return getIt<UserRepository>().watchUser(userId);
});

final currentUserIDProvider = StreamProvider<String?>((ref) {
  return getIt<AuthService>().onAuthStateChanged;
});
