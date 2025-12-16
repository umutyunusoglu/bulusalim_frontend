import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:bulusalim/scaffold_with_navbar.dart';
import 'package:bulusalim/screens/camera/camera_page.dart';
import 'package:bulusalim/screens/chat/chat_page.dart';
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
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,

  // Uygulama artık '/' rotasından (yani SignInScreen'den) başlar.
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
        // 1. SIRA: MAP (Harita) - En Solda
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

        // 3. SIRA: HOME (Ana Sayfa) - Ortada
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
              routes: [
                // Home içinden Profile gidilince Navbar KALSIN
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

        // 4. SIRA: CHAT (Sohbet)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) => const ChatPage(),
            ),
          ],
        ),

        // 5. SIRA: PROFİL (Kendi Profilin) - En Sağda
        // ----------------------------------------------------------
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/my_profile',
              builder: (context, state) {
                final sessionService = getIt<SessionService>();
                final myUserId = sessionService.currentUser?.userID;
                // Eğer ID varsa o ID ile sayfayı aç, yoksa boş string gönder (veya login'e at)
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
      parentNavigatorKey: _rootNavigatorKey, // Navbar'ın üstüne çıkar
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

    // 4. KAMERA (Dump)
    GoRoute(
      path: '/camera',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CameraPage(),
    ),
  ],
);
