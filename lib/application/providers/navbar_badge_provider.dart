import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/data/services/navbar_badge_service_impl.dart';
import 'package:outnest/domain/services/navbar_badge_service.dart';

final navBarBadgeProvider = Provider<NavBarBadgeService>((ref) {
  final service = NavBarBadgeServiceImpl();
  ref.onDispose(service.dispose);
  return service;
});

final navBarBadgeStateProvider = StreamProvider<Set<int>>((ref) {
  final service = ref.watch(navBarBadgeProvider);
  return service.badgesStream;
});