import 'dart:async';

import 'package:outnest/domain/services/navbar_badge_service.dart';

class NavBarBadgeServiceImpl implements NavBarBadgeService {
  final Set<int> _tabsWithBadge = <int>{};
  final StreamController<Set<int>> _controller =
      StreamController<Set<int>>.broadcast();

  @override
  Set<int> get activeBadges => Set.unmodifiable(_tabsWithBadge);

  @override
  Stream<Set<int>> get badgesStream => _controller.stream;

  @override
  bool hasBadge(int tabIndex) => _tabsWithBadge.contains(tabIndex);

  @override
  void setBadge({required int tabIndex, required bool visible}) {
    final changed = visible
        ? _tabsWithBadge.add(tabIndex)
        : _tabsWithBadge.remove(tabIndex);
    if (changed) _emit();
  }

  @override
  void clearBadge(int tabIndex) {
    setBadge(tabIndex: tabIndex, visible: false);
  }

  @override
  void clearAll() {
    if (_tabsWithBadge.isEmpty) return;
    _tabsWithBadge.clear();
    _emit();
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(Set.unmodifiable(_tabsWithBadge));
  }

  @override
  void dispose() {
    _controller.close();
  }
}