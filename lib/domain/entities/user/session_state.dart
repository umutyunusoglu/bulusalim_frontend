// lib/core/services/session/session_state.dart

import 'package:flutter/foundation.dart';
import 'package:outnest/core/utils/types/types.dart'; // Identifier typedef burada varsayılmıştır
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';

@immutable
class SessionState {
  final UserEntity? user;
  final List<EventEntity> ongoingEvents;
  final List<Identifier> followerIds;
  final List<Identifier> followeeIds;

  const SessionState({
    this.user,
    this.ongoingEvents = const [],
    this.followerIds = const [],
    this.followeeIds = const [],
  });

  // Derived Getters
  int get followerCount => followerIds.length;
  int get followeeCount => followeeIds.length;
  bool get isAuthenticated => user != null;

  static const empty = SessionState();

  // Sadece değişen alanı günceller, diğerlerini korur.
  SessionState copyWith({
    UserEntity? user,
    List<EventEntity>? ongoingEvents,
    List<Identifier>? followerIds,
    List<Identifier>? followeeIds,
  }) {
    return SessionState(
      user: user ?? this.user,
      ongoingEvents: ongoingEvents ?? this.ongoingEvents,
      followerIds: followerIds ?? this.followerIds,
      followeeIds: followeeIds ?? this.followeeIds,
    );
  }

  // Eşitlik kontrolü (ValueNotifier optimizasyonu için)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionState &&
        other.user == user &&
        listEquals(other.ongoingEvents, ongoingEvents) &&
        listEquals(other.followerIds, followerIds) &&
        listEquals(other.followeeIds, followeeIds);
  }

  @override
  int get hashCode => Object.hash(
    user,
    Object.hashAll(ongoingEvents),
    Object.hashAll(followerIds),
    Object.hashAll(followeeIds),
  );
}
