import 'dart:async';

abstract class NavBarBadgeService {
  Set<int> get activeBadges;

  Stream<Set<int>> get badgesStream;

  bool hasBadge(int tabIndex);

  void setBadge({required int tabIndex, required bool visible});

  void clearBadge(int tabIndex);

  void clearAll();

  void dispose();
}