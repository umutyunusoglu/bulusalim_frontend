import 'package:flutter/material.dart';
import 'package:outnest/domain/entities/badges/badge_entity.dart';

abstract class BadgeRepository {
  Future<List<BadgeEntity>> getAllBadges();
  Future<List<BadgeEntity>> getBadgesOfUser(String userID);
  Future<List<BadgeEntity>> getBadgesOfCategory(String category);
}
