import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/stacked_avatars.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/scaffold_with_navbar.dart';
import 'package:outnest/screens/auth/login_page.dart';
import 'package:outnest/screens/auth/otp_verification_page.dart';
import 'package:outnest/screens/auth/register_info_page.dart';
import 'package:outnest/screens/auth/register_page.dart';
import 'package:outnest/screens/auth/welcome_page.dart';
import 'package:outnest/screens/camera/camera_page.dart';
import 'package:outnest/screens/chat/chat_page.dart';
import 'package:outnest/screens/chat/event_settings_page.dart';
import 'package:outnest/screens/chat/my_events_page.dart';
import 'package:outnest/screens/home/home_page.dart';
import 'package:outnest/screens/map/map_page.dart';
import 'package:outnest/screens/notification/follow_request.dart';
import 'package:outnest/screens/notification/notification_page.dart';
import 'package:outnest/screens/profile/profile_page.dart';
import 'package:outnest/screens/search/search_page.dart';
import 'package:outnest/screens/settings/edit_profile_page.dart';
import 'package:outnest/screens/settings/settings.dart';

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

  // 1. BAŞLANGIÇ ROTASI WELCOME
  initialLocation: '/welcome',

  // 2. OTURUM KONTROLÜ (REDIRECT)
  redirect: (context, state) {
    final sessionService = getIt<SessionService>();
    final isLoggedIn = sessionService.currentUser != null;

    final goingTo = state.uri.toString();

    // Giriş sayfaları (Auth rotaları)
    final isAuthRoute =
        goingTo == '/welcome' ||
        goingTo == '/login' ||
        goingTo == '/register' ||
        goingTo == '/verification-code-field' ||
        goingTo == '/login-verification' ||
        goingTo == '/register-info';

    // Debug sayfasına izin ver
    final isDebugRoute = goingTo == '/debug';

    // SENARYO A: Kullanıcı giriş YAPMAMIŞSA
    if (!isLoggedIn) {
      // Auth rotalarındaysa veya debug daysa sorun yok
      if (isAuthRoute || isDebugRoute) return null;

      // İçerideki sayfalara girmeye çalışıyorsa Welcome'a at
      return '/welcome';
    }

    // SENARYO B: Kullanıcı giriş YAPMIŞSA
    if (isLoggedIn) {
      // Auth sayfalarına girmeye çalışıyorsa Home'a at
      if (isAuthRoute) return '/home';
    }

    return null;
  },

  routes: [
    // --- AUTH ROTALARI ---
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    // Login için OTP Rotası (isLogin: true)
    GoRoute(
      path: '/login-verification',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final verificationID = extra?['verificationID'] as String?;

        return OtpVerificationPage(
          isLogin: true,
          verificationID: verificationID,
        );
      },
    ),

    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    // Register için OTP Rotası (isLogin: false)
    GoRoute(
      path: '/verification-code-field',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final verificationID = extra?['verificationID'] as String?;

        return OtpVerificationPage(
          isLogin: false,
          verificationID: verificationID,
        );
      },
    ),
    // Kayıt Bilgileri Sihirbazı
    GoRoute(
      path: '/register-info',
      builder: (context, state) => const RegisterInfoPage(),
    ),

    // --- DEBUG ROTASI ---
    GoRoute(
      path: '/debug',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HomePage(),
    ),

    // --- BOTTOM NAVIGATION BAR (SHELL) ---
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

    // --- FULL SCREEN (NAVBARSIZ) SAYFALAR ---

    // AYARLAR
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsPage(),
      routes: [
        GoRoute(
          path: 'edit-profile',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const EditProfilePage(),
        ),
      ],
    ),

    // BİLDİRİMLER
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationPage(),
    ),
    GoRoute(
      path: '/follow-requests',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FollowRequestsPage(),
    ),

    // HARİTA SEÇİCİLER
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

    // KAMERA
    GoRoute(
      path: '/camera',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CameraPage(),
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

        final eventEntity = extra?['event'] as EventEntity?;

        return ChatPage(
          eventID: eventID,
          event: eventEntity!,
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
              remainingTime: (extra?['remainingTime'] as String?) ?? '',
              creatorID: (extra?['creatorID'] as String?) ?? '',
            );
          },
        ),
      ],
    ),
  ],
);
