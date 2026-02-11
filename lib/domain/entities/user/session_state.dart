// lib/core/services/session/session_state.dart

import 'package:flutter/foundation.dart';
import 'package:outnest/core/utils/types/types.dart'; // Identifier typedef burada varsayılmıştır
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';

@immutable
class SessionState {
  const SessionState({
    this.user,
    this.ongoingEvents = const [],
    this.upcomingEvents = const [],
    this.followers = const [],
    this.followees = const [],
    this.blockedUsers = const [],
  });

  final UserEntity? user;
  final List<EventEntity> ongoingEvents;
  final List<EventEntity> upcomingEvents;
  final List<CompactUserEntity> followers;
  final List<CompactUserEntity> followees;
  final List<CompactUserEntity> blockedUsers;

  // Derived Getters
  int get followerCount => followers.length;
  int get followeeCount => followees.length;
  bool get isAuthenticated => user != null;

  static const empty = SessionState();

  // Sadece değişen alanı günceller, diğerlerini korur.
  SessionState copyWith({
    UserEntity? user,
    List<EventEntity>? ongoingEvents,
    List<EventEntity>? upcomingEvents,
    List<CompactUserEntity>? followers,
    List<CompactUserEntity>? followees,
    List<CompactUserEntity>? blockedUsers,
  }) {
    return SessionState(
      user: user ?? this.user,
      ongoingEvents: ongoingEvents ?? this.ongoingEvents,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      followers: followers ?? this.followers,
      followees: followees ?? this.followees,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }

  // Eşitlik kontrolü (ValueNotifier optimizasyonu için)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionState &&
        other.user == user &&
        listEquals(other.ongoingEvents, ongoingEvents) &&
        listEquals(other.upcomingEvents, upcomingEvents) && // Eklendi
        listEquals(other.followers, followers) &&
        listEquals(other.followees, followees) &&
        listEquals(other.blockedUsers, blockedUsers); // Eklendi (Kritik!)
  }

  @override
  int get hashCode => Object.hash(
    user,
    Object.hashAll(ongoingEvents),
    Object.hashAll(upcomingEvents), // Eklendi
    Object.hashAll(followers),
    Object.hashAll(followees),
    Object.hashAll(blockedUsers), // Eklendi
  );
}
