import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/stacked_avatars.dart'; // AvatarInfo için
import 'package:bulusalim/domain/entities/user/compact_user_entity.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:bulusalim/scaffold_with_navbar.dart';
import 'package:bulusalim/screens/camera/camera_page.dart';
import 'package:bulusalim/screens/chat/chat_page.dart';
import 'package:bulusalim/screens/chat/event_settings_page.dart';
import 'package:bulusalim/screens/chat/my_events_page.dart';
import 'package:bulusalim/screens/home/home_page.dart';
import 'package:bulusalim/screens/login/login_screen.dart';
import 'package:bulusalim/screens/map/map_page.dart';
import 'package:bulusalim/screens/profile/profile_page.dart';
import 'package:bulusalim/screens/register_screen.dart';
import 'package:bulusalim/screens/search/search_page.dart';
import 'package:bulusalim/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

List<AvatarInfo> _mapToAvatarInfo(List<dynamic> rawList) {
  return rawList.map((e) {
    if (e is CompactUserEntity) {
      return AvatarInfo(imageUrl: e.profileImageUrl, userId: e.userID);
    } else if (e is AvatarInfo) {
      return e;
    }
    return AvatarInfo(imageUrl: 'https://picsum.photos/200', userId: '');
  }).toList();
}

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // 1. BOTTOM NAVIGATION BAR OLAN SAYFALAR (SHELL)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavbar(navigationShell: navigationShell);
      },
      branches: [
        // BRANCH 1: MAP
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapPage(),
            ),
          ],
        ),
        // BRANCH 2: SEARCH
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchPage(),
            ),
          ],
        ),
        // BRANCH 3: HOME
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
              routes: [
                GoRoute(
                  path: 'profile/:userId',
                  builder: (context, state) {
                    final userId = state.pathParameters['userId'] ?? '';
                    return ProfilePage(profileUserID: userId);
                  },
                ),
              ],
            ),
          ],
        ),
        // BRANCH 4: CHAT LISTESI
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) => const MyEventsPage(),
            ),
          ],
        ),
        // BRANCH 5: MY PROFILE
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/my_profile',
              builder: (context, state) {
                final sessionService = getIt<SessionService>();
                final myUserId = sessionService.currentUser?.userID;
                return ProfilePage(profileUserID: myUserId ?? '');
              },
            ),
          ],
        ),
      ],
    ),

    // 2. NAVBARSIZ SAYFALAR (FULL SCREEN / ROOT ROUTES)
    GoRoute(
      path: '/pick-location-map',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return const MapPage(isLocationPicker: true);
      },
    ),
    GoRoute(
      path: '/pick-time-map',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return const MapPage(isTimePicker: true);
      },
    ),

    // SOHBET ODASI
    GoRoute(
      path: '/chat/room/:eventID',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final eventID = state.pathParameters['eventID'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;

        final rawAvatars = (extra?['avatars'] as List?) ?? [];
        final safeAvatars = _mapToAvatarInfo(rawAvatars);

        final eventDate = extra?['date'] as DateTime? ?? DateTime.now();

        return ChatPage(
          eventID: eventID,
          chatTitle: (extra?['title'] as String?) ?? 'Sohbet',
          participantAvatars: safeAvatars,
          location: (extra?['location'] as String?) ?? '',
          participantStatus: (extra?['participants'] as String?) ?? '',
          eventDate: eventDate,
          creatorID: (extra?['creatorID'] as String?) ?? '',
          creatorProfileImage: (extra?['creatorProfileImage'] as String?) ?? '',
        );
      },
      routes: [
        // CHAT AYARLARI
        GoRoute(
          path: 'settings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final eventID = state.pathParameters['eventID'] ?? '';
            final extra = state.extra as Map<String, dynamic>?;

            final rawAvatars = (extra?['avatars'] as List?) ?? [];
            final safeAvatars = _mapToAvatarInfo(rawAvatars);

            return EventSettingsPage(
              eventID: eventID,
              chatTitle: (extra?['title'] as String?) ?? 'Ayarlar',
              participantAvatars: safeAvatars,
              location: (extra?['location'] as String?) ?? '',
              participantStatus: (extra?['participants'] as String?) ?? '',
              remainingTime:
                  (extra?['remainingTime'] as String?) ??
                  '', // Hata almamak için null check
              creatorID: (extra?['creatorID'] as String?) ?? '',
            );
          },
        ),
      ],
    ),

    // DİĞER SAYFALAR
    GoRoute(
      path: '/',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/camera',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CameraPage(),
    ),
  ],
);
