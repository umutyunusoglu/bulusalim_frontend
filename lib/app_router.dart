import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/auth/view/login_page.dart';
import 'package:outnest/presentation/auth/view/otp_verification_page.dart';
import 'package:outnest/presentation/auth/view/register_info_page.dart';
import 'package:outnest/presentation/auth/view/register_page.dart';
import 'package:outnest/presentation/auth/view/welcome_page.dart';
import 'package:outnest/presentation/camera/view/camera_page.dart';
import 'package:outnest/presentation/chat/view/chat_page.dart';
import 'package:outnest/presentation/chat/view/event_settings_page.dart';
import 'package:outnest/presentation/chat/view/my_events_page.dart';
import 'package:outnest/presentation/debug/debug_nsfw_screen.dart';
import 'package:outnest/presentation/event_verification/my_qr_page.dart';
import 'package:outnest/presentation/event_verification/qr_scanner_page.dart';
import 'package:outnest/presentation/event_verification/verification_splash_screen.dart';
import 'package:outnest/presentation/groups/view/groups_page.dart';
import 'package:outnest/presentation/home/view/home_page.dart';
import 'package:outnest/presentation/init_screen.dart';
import 'package:outnest/presentation/map/view/map_page.dart';
import 'package:outnest/presentation/notification/view/follow_request_page.dart';
import 'package:outnest/presentation/notification/view/notification_page.dart';
import 'package:outnest/presentation/profile/view/profile_dispatcher.dart';
import 'package:outnest/presentation/search/view/search_page.dart';
import 'package:outnest/presentation/settings/view/account_settings_page.dart';
import 'package:outnest/presentation/settings/view/edit_profile_page.dart';
import 'package:outnest/presentation/settings/view/settings_page.dart';
import 'package:outnest/presentation/shared/event_card/stacked_avatars.dart';
import 'package:outnest/scaffold_with_navbar.dart';

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
  initialLocation: '/splash',
  errorBuilder: (context, state) {
    debugPrint('GoRouter Hatası: ${state.error}');
    return const HomePage();
  },
  redirect: (context, state) {
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const InitScreen(),
    ),
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
          resendToken: extra?['resendToken'] as int?,
          phoneNumber: extra?['phoneNumber'] as String?,
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
          phoneNumber: extra?['phoneNumber'] as String?,
          resendToken: extra?['resendToken'] as int?,
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
      builder: (context, state) => const NsfwDebugScreen(),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavbar(navigationShell: navigationShell);
      },
      branches: [
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
                    return ProfileDispatcher(profileUserID: userId);
                  },
                ),
                GoRoute(
                  path: 'event_verification',
                  builder: (context, state) {
                    final event = state.extra as EventEntity?;
                    return VerificationSplashScreen(event!);
                  },
                  routes: [
                    GoRoute(
                      path: 'qr_scanner',
                      builder: (context, state) {
                        final event = state.extra as EventEntity?;
                        return QRScannerScreen(event!);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchPage(),
              routes: [
                GoRoute(
                  path: 'profile/:userId',
                  builder: (context, state) {
                    final userId = state.pathParameters['userId'] ?? '';

                    return ProfileDispatcher(profileUserID: userId);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) {
                final openCreate = state.extra as bool? ?? false;
                return MapPage(openCreateOnLoad: openCreate);
              },
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
                return ProfileDispatcher(profileUserID: myUserId ?? '');
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
          builder: (context, state) => const EditProfilePage(),
        ),
        GoRoute(
          path: 'edit-account',
          builder: (context, state) => const AccountSettingsPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/groups',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GroupsPage(),
    ),
    GoRoute(
      path: '/my-qr',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MyQrPage(),
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
