import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/stacked_avatars.dart'; // <-- 1. BU EKLENDİ (AvatarInfo için)
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:bulusalim/scaffold_with_navbar.dart';
import 'package:bulusalim/screens/camera/camera_page.dart';
import 'package:bulusalim/screens/chat/chat_page.dart';
import 'package:bulusalim/screens/chat/event_settings_page.dart'; // <-- 2. BU EKLENDİ (Ayarlar Sayfası)
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

// 1. Ana Yönlendirici (Navbar'ın üstüne çıkan tam ekran sayfalar için)
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

// 2. Shell Yönlendirici (Navbar içindeki sekmeler için)

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,

  // Uygulama '/' rotasından (SignInScreen) başlar.
  initialLocation: '/',

  routes: [
    // ----------------------------------------------------------
    // A. NAVBAR'LI KISIM (SHELL ROUTE)
    // ----------------------------------------------------------
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavbar(navigationShell: navigationShell);
      },
      branches: [
        // 1. SIRA: MAP (Harita)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapPage(),
            ),
          ],
        ),

        // 2. SIRA: SEARCH (Arama)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchPage(),
            ),
          ],
        ),

        // 3. SIRA: HOME (Ana Sayfa)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
              routes: [
                GoRoute(
                  path: 'profile/:userId',
                  builder: (context, state) {
                    final userId = state.pathParameters['userId']!;
                    return ProfilePage(profileUserID: userId);
                  },
                ),
              ],
            ),
          ],
        ),

        // 4. SIRA: CHAT (Etkinliklerim/Sohbet)
        StatefulShellBranch(
          routes: [
            // 1. ANA EKRAN: LİSTE (MyEventsPage)
            GoRoute(
              path: '/chat',
              builder: (context, state) => const MyEventsPage(),

              // 2. ALT EKRAN: SOHBET ODASI (ChatPage)
              routes: [
                GoRoute(
                  path: 'room/:eventID', // URL: /chat/room/123
                  builder: (context, state) {
                    final eventID = state.pathParameters['eventID']!;
                    final extra = state.extra as Map<String, dynamic>?;

                    // --- AVATAR LISTESINI GÜVENLİ ÇEKME ---
                    var avatarList = <AvatarInfo>[];
                    if (extra != null && extra['avatars'] != null) {
                      avatarList = (extra['avatars'] as List<dynamic>)
                          .map((e) => e as AvatarInfo)
                          .toList();
                    }
                    // --------------------------------------

                    return ChatPage(
                      eventID: eventID,
                      chatTitle: (extra?['title'] as String?) ?? 'Sohbet',
                      participantAvatars: avatarList, // LİSTE BURADA
                      location: (extra?['location'] as String?) ?? '',
                      participantStatus:
                          (extra?['participants'] as String?) ?? '',
                      remainingTime: (extra?['time'] as String?) ?? '',
                      creatorID: (extra?['creatorID'] as String?) ?? '',
                    );
                  },
                  // 3. ALT EKRAN: AYARLAR (EventSettingsPage)
                  routes: [
                    GoRoute(
                      path: 'settings', // URL: /chat/room/123/settings
                      builder: (context, state) {
                        final eventID = state.pathParameters['eventID']!;
                        final extra = state.extra as Map<String, dynamic>?;

                        var avatarList = <AvatarInfo>[];
                        if (extra != null && extra['avatars'] != null) {
                          avatarList = (extra['avatars'] as List<dynamic>)
                              .map((e) => e as AvatarInfo)
                              .toList();
                        }

                        return EventSettingsPage(
                          eventID: eventID,
                          chatTitle: (extra?['title'] as String?) ?? 'Ayarlar',
                          participantAvatars: avatarList,
                          location: (extra?['location'] as String?) ?? '',
                          participantStatus:
                              (extra?['participants'] as String?) ?? '',
                          remainingTime: (extra?['time'] as String?) ?? '',
                          creatorID: (extra?['creatorID'] as String?) ?? '',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // 5. SIRA: PROFİL (Kendi Profilin)
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

    // ----------------------------------------------------------
    // B. NAVBAR'SIZ TAM EKRAN SAYFALAR (ROOT ROUTE)
    // ----------------------------------------------------------

    // 1. AÇILIŞ EKRANI (SignIn)
    GoRoute(
      path: '/',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SignInScreen(),
    ),

    // 2. GİRİŞ YAP (Login)
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),

    // 3. KAYIT OL (Register)
    GoRoute(
      path: '/register',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RegisterScreen(),
    ),

    // 4. KAMERA
    GoRoute(
      path: '/camera',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CameraPage(),
    ),
  ],
);
