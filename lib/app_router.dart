import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/stacked_avatars.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/services/file_service.dart';
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
    return AvatarInfo(
      imageUrl: FileService.defaultProfileImageUrl(),
      userId: '',
    );
  }).toList();
}

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,

  // Başlangıç rotası
  initialLocation: '/welcome',

  redirect: (context, state) async {
    final AuthService authService = getIt<AuthService>();
    final UserRepository userRepository = getIt<UserRepository>();
    final isLoggedIn = await authService.isUserLoggedIn();

    final goingTo = state.uri.toString();
    final isAuthRoute = [
      '/welcome',
      '/login',
      '/register',
      '/verification-code-field',
      '/login-verification',
    ].contains(goingTo);

    final isRegisterInfo = goingTo == '/register-info';
    final isDebugRoute = goingTo == '/debug';

    // 1. Giriş yapmamış kullanıcı
    if (!isLoggedIn) {
      // Auth rotalarından birindeyse veya debug sayfasındaysa bırak gitsin
      if (isAuthRoute || isRegisterInfo || isDebugRoute) return null;
      // Değilse welcome'a zorla
      return '/welcome';
    }

    // 2. Giriş yapmış kullanıcı
    if (isLoggedIn) {
      final isUserRegistered = await userRepository.isUserRegistered(
        authService.getCurrentUserID(),
      );

      if (isUserRegistered) {
        // Kullanıcı kayıtlı ve ana uygulamaya girmek istiyor.
        // Eğer hala auth sayfalarındaysa /home'a at, değilse (yani zaten içerdeyse) gitmek istediği yere izin ver.
        if (isAuthRoute || isRegisterInfo) {
          return '/home';
        }
        return null; // Mevcut rotasına devam etmesine izin ver (örn: /chat, /profile vs.)
      } else {
        // Kaydı tamam değilse ve register-info'da değilse oraya zorla
        if (!isRegisterInfo) return '/register-info';
        return null;
      }
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
    GoRoute(
      path: '/register-info',
      builder: (context, state) => const RegisterInfoPage(),
    ),

    // --- DEBUG ---
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
      builder: (context, state) => const MapPage(isLocationPicker: true),
    ),
    GoRoute(
      path: '/pick-time-map',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MapPage(isTimePicker: true),
    ),

    // KAMERA
    GoRoute(
      path: '/camera',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final event = extra?['event'] as EventEntity?;
        return CameraPage(event: event!);
      },
    ),

    // --- SOHBET ODASI VE ALT ROTALARI ---
    GoRoute(
      path: '/chat/room/:eventID',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final eventID = state.pathParameters['eventID'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;

        final rawAvatars = (extra?['avatars'] as List?) ?? [];
        final safeAvatars = _mapToAvatarInfo(rawAvatars);

        return ChatPage(
          eventID: eventID,
          event: extra?['event'] as EventEntity,
          chatTitle: (extra?['title'] as String?) ?? 'Sohbet',
          participantAvatars: safeAvatars,
          location: (extra?['location'] as String?) ?? '',
          participantStatus: (extra?['participants'] as String?) ?? '',
          eventDate: extra?['date'] as DateTime? ?? DateTime.now(),
          creatorID: (extra?['creatorID'] as String?) ?? '',
          creatorProfileImage: (extra?['creatorProfileImage'] as String?) ?? '',
        );
      },
      routes: [
        // Child route: sadece 'settings' (parent eventID parametresini kullanır)
        GoRoute(
          path: 'settings',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final rawAvatars = (extra?['avatars'] as List?) ?? [];
            final safeAvatars = _mapToAvatarInfo(rawAvatars);

            return EventSettingsPage(
              eventID: state.pathParameters['eventID'] ?? '',
              chatTitle: (extra?['title'] as String?) ?? 'Buluşma Ayarları',
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

    // --- BAĞIMSIZ EVENT SETTINGS (EventCard / root çağrılar için) ---
    GoRoute(
      name: 'eventManagement',
      path: '/event-management/:mgmtID',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final eventID = state.pathParameters['mgmtID'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;
        final rawAvatars = (extra?['avatars'] as List?) ?? [];
        final safeAvatars = _mapToAvatarInfo(rawAvatars);

        return EventSettingsPage(
          eventID: eventID,
          chatTitle: (extra?['title'] as String?) ?? 'Buluşma Ayarları',
          participantAvatars: safeAvatars,
          location: (extra?['location'] as String?) ?? '',
          participantStatus: (extra?['participants'] as String?) ?? '',
          remainingTime: (extra?['remainingTime'] as String?) ?? '',
          creatorID: (extra?['creatorID'] as String?) ?? '',
        );
      },
    ),
  ],
);
