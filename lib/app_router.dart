import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/stacked_avatars.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/push_notifications_service.dart';
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
import 'package:outnest/screens/debug/debug_nsfw_screen.dart';
import 'package:outnest/screens/home/home_page.dart';
import 'package:outnest/screens/map/map_page.dart';
import 'package:outnest/screens/notification/follow_request.dart';
import 'package:outnest/screens/notification/notification_page.dart';
import 'package:outnest/screens/profile/profile_page.dart';
import 'package:outnest/screens/search/search_page.dart';
import 'package:outnest/screens/settings/edit_profile_page.dart';
import 'package:outnest/screens/settings/settings.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
bool _isAppInitialized = false;

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
  initialLocation: '/welcome',
  errorBuilder: (context, state) {
    debugPrint('GoRouter Hatası: ${state.error}');
    // Kullanıcıyı güvenli bir limana (Home) yönlendir
    return const HomePage();
  },
  redirect: (context, state) async {
    final goingTo = state.uri.toString();
    final isAuthRoute = [
      '/welcome',
      '/login',
      '/register',
      '/verification-code-field',
      '/login-verification',
    ].contains(goingTo);

    if (!isAuthRoute) {
      // Auth route değilse ve kullanıcı giriş yapmamışsa aşağıda yakalanır,
      // şimdilik null döndürüp akışa bırakıyoruz, aşağıda kontrol edilecek.
      return null;
    }

    final authService = getIt<AuthService>();
    final userRepository = getIt<UserRepository>();

    // AuthService genelde hafiftir (cache'den okur), her seferinde çağrılmasında sakınca yoktur.
    final isLoggedIn = await authService.isUserLoggedIn();

    final isRegisterInfo = goingTo == '/register-info';
    final isDebugRoute = goingTo == '/debug';

    // 1. Giriş yapmamış kullanıcı
    if (!isLoggedIn) {
      // ÖNEMLİ: Kullanıcı çıkış yaptıysa flag'i sıfırla ki tekrar girdiğinde init çalışsın.
      _isAppInitialized = false;

      if (isAuthRoute || isRegisterInfo || isDebugRoute) return null;
      return '/welcome';
    }

    // 2. Giriş yapmış kullanıcı
    if (isLoggedIn) {
      // --- DEĞİŞİKLİK BURADA BAŞLIYOR ---

      // Eğer uygulama henüz initialize edilmediyse kontrolleri yap
      if (!_isAppInitialized) {
        final isUserRegistered = await userRepository.isUserRegistered(
          authService.getCurrentUserID(),
        );

        if (isUserRegistered) {
          // Kullanıcı kayıtlı, servisleri BİR KERE başlat.
          final pushService = getIt<PushNotificationsService>();
          final sessionService = getIt<SessionService>();

          pushService.initialize();
          await sessionService.init();

          // Her şey başarılı, flag'i true yap. Artık sayfa geçişlerinde buraya girmeyecek.
          _isAppInitialized = true;

          // Eğer login/welcome sayfalarındaysa home'a at
          if (isAuthRoute || isRegisterInfo) {
            return '/home';
          }
          return null; // Gitmek istediği yere izin ver
        } else {
          // Kayıtlı değilse register-info'ya zorla
          if (!isRegisterInfo) return '/register-info';
          return null;
        }
      }
      // --- UYGULAMA ZATEN INITIALIZE EDİLMİŞSE ---
      else {
        // Kullanıcı zaten içeride ve init olmuş.
        // Sadece yanlışlıkla auth sayfalarına dönmesini engelle.
        if (isAuthRoute || isRegisterInfo) {
          return '/home';
        }

        // Diğer tüm durumlar (chat, profil vs.) için geçişe izin ver.
        return null;
      }
    }

    return null;
  },
  routes: [
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
        return OtpVerificationPage(
          isLogin: true,
          verificationID: extra?['verificationID'] as String?,
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
        return OtpVerificationPage(
          verificationID: extra?['verificationID'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/register-info',
      builder: (context, state) => const RegisterInfoPage(),
    ),
    GoRoute(
      path: '/debug',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => NsfwDebugScreen(),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavbar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
              routes: [
                GoRoute(
                  path: 'profile/:userId',
                  // DİKKAT: Buradan parentNavigatorKey kaldırıldı çünkü branch içinde.
                  // Eğer tam ekran olmasını istiyorsanız bu rotayı ShellRoute dışına taşımalısınız.
                  builder: (context, state) {
                    final userId = state.pathParameters['userId'] ?? '';
                    return ProfilePage(profileUserID: userId);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) => const MyEventsPage(),
            ),
          ],
        ),
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

    // --- ROOT ROTALARI (NAVBARSIZ) ---
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsPage(),
      routes: [
        GoRoute(
          path: 'edit-profile',
          // Child root zaten parent'ının navigator'ını kullanır
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
    GoRoute(
      path: '/camera',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final event = extra?['event'] as EventEntity?;
        return CameraPage(event: event!);
      },
    ),
    GoRoute(
      path: '/chat/room/:eventID',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final eventID = state.pathParameters['eventID'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;

        final safeAvatars = _mapToAvatarInfo(
          (extra?['avatars'] as List?) ?? [],
        );

        return ChatPage(
          eventID: eventID,
          event: extra?['event'] as EventEntity,
          chatTitle: (extra?['title'] as String?) ?? 'Sohbet',
          participantAvatars: safeAvatars,
          location: (extra?['location'] as String?) ?? '',
          participantStatus: (extra?['participants'] as String?) ?? '',
          eventDate: extra?['startTime'] as DateTime? ?? DateTime.now(),
          creatorID: (extra?['creatorID'] as String?) ?? '',
          creatorProfileImage: (extra?['creatorProfileImage'] as String?) ?? '',
        );
      },

      routes: [
        GoRoute(
          path: 'settings',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return EventSettingsPage(
              eventID: state.pathParameters['eventID'] ?? '',
              chatTitle: (extra?['title'] as String?) ?? 'Buluşma Ayarları',
              participantAvatars: _mapToAvatarInfo(
                (extra?['avatars'] as List?) ?? [],
              ),
              location: (extra?['location'] as String?) ?? '',
              participantStatus: (extra?['participants'] as String?) ?? '',
              remainingTime: (extra?['remainingTime'] as String?) ?? '',
              creatorID: (extra?['creatorID'] as String?) ?? '',
              event: extra?['event'] as EventEntity,
            );
          },
        ),
      ],
    ),
    GoRoute(
      name: 'eventManagement',
      path: '/event-management/:mgmtID',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return EventSettingsPage(
          eventID: state.pathParameters['mgmtID'] ?? '',
          chatTitle: (extra?['title'] as String?) ?? 'Buluşma Ayarları',
          participantAvatars: _mapToAvatarInfo(
            (extra?['avatars'] as List?) ?? [],
          ),
          location: (extra?['location'] as String?) ?? '',
          participantStatus: (extra?['participants'] as String?) ?? '',
          remainingTime: (extra?['remainingTime'] as String?) ?? '',
          creatorID: (extra?['creatorID'] as String?) ?? '',
          event: extra?['event'] as EventEntity,
        );
      },
    ),
  ],
);
