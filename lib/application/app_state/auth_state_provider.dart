import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/domain/services/auth_service.dart';

final authStateProvider = StreamProvider<String?>((ref) {
  return getIt<AuthService>().onAuthStateChanged;
});
