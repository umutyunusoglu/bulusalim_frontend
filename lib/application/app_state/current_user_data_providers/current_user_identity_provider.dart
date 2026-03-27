import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/app_state/auth_state_provider.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';

final currentUserEntityProvider = StreamProvider<UserEntity?>((ref) {
  final authState = ref.watch(authStateProvider);

  // loading → henüz bilmiyoruz, hiç emit etme
  if (authState.isLoading) return const Stream.empty();

  final userId = authState.value;

  // null → oturum yok
  if (userId == null) return Stream.value(null);

  return getIt<UserRepository>().watchUser(userId);
});

final currentUserIDProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value;
});
