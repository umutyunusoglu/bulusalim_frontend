import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart'; // GetIt'i import etmeyi unutma!
import 'package:outnest/application/providers/nav_bar_active_index_provider.dart';
import 'package:outnest/application/providers/navbar_badge_provider.dart';
import 'package:outnest/presentation/debug/debug_panel.dart';

class ScaffoldWithNavbar extends ConsumerStatefulWidget {
  const ScaffoldWithNavbar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavbar> createState() => _ScaffoldWithNavbarState();
}

class _ScaffoldWithNavbarState extends ConsumerState<ScaffoldWithNavbar> {
  static const int _chatTabIndex = 3;
  static const int _feedTabIndex = 0;

  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final NavBarActiveIndexNotifier navBarActiveIndexNotifier = ref.read(
        navBarActiveIndexProvider.notifier,
      );
      navBarActiveIndexNotifier.setIndex(widget.navigationShell.currentIndex);
    });
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) {
      _handleNotificationPayload(message.data);
    });
  }

  @override
  void dispose() {
    _foregroundMessageSubscription?.cancel();
    super.dispose();
  }

  bool _isChatRelatedPayload(Map<String, dynamic> payload) {
    final keys = payload.keys.map((k) => k.toLowerCase()).join(' ');
    final values = payload.values
        .map((v) => v.toString().toLowerCase())
        .join(' ');

    final haystack = '$keys $values';
    return haystack.contains('chat') ||
        haystack.contains('message') ||
        haystack.contains('meeting_chat') ||
        haystack.contains('event_chat');
  }

  void _handleNotificationPayload(Map<String, dynamic> payload) {
    if (_isChatRelatedPayload(payload)) {
      ref
          .read(navBarBadgeProvider)
          .setBadge(
            tabIndex: _chatTabIndex,
            visible: true,
          );
    }
  }

  void _openDebugNotificationPanel(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notification Test Panel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Guide: payload tests only affect chat tab dot. Firestore seeds test the full notification builder flow.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Payload: event_chat'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _handleNotificationPayload({
                      'type': 'event_chat',
                      'body': 'new message',
                    });
                    _showDebugSnack('Chat payload simulated');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.mark_chat_unread_outlined),
                  title: const Text('Payload: message keyword'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _handleNotificationPayload({
                      'messageType': 'chat_message',
                      'content': 'hello',
                    });
                    _showDebugSnack('Message payload simulated');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('Payload: non-chat'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _handleNotificationPayload({
                      'type': 'follow_request',
                      'body': 'new follower',
                    });
                    _showDebugSnack('Non-chat payload simulated');
                  },
                ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.add_alert_outlined),
                  title: const Text('Seed Firestore: invite notification'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _seedNotificationDoc(
                      type: 'invite',
                      title: 'Debug Invite',
                      message: 'You were invited to a meeting',
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.warning_amber_outlined),
                  title: const Text('Seed Firestore: warning notification'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _seedNotificationDoc(
                      type: 'warning',
                      title: 'Debug Warning',
                      message: 'Please review your recent activity',
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_add_alt_1_outlined),
                  title: const Text('Seed Firestore: follow notification'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _seedFollowNotificationDoc();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('Seed Firestore: both collections'),
                  subtitle: const Text(
                    'Writes to notifications + followNotifications',
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _seedFirestoreNotifications();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.open_in_new),
                  title: const Text('Open /notifications'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (!mounted) return;
                    context.push('/notifications');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.open_in_new),
                  title: const Text('Open /follow-requests'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (!mounted) return;
                    context.push('/follow-requests');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.clear),
                  title: const Text('Clear chat badge'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ref.read(navBarBadgeProvider).clearBadge(_chatTabIndex);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDebugSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _markFeedBadgeForDebug() {
    ref
        .read(navBarBadgeProvider)
        .setBadge(
          tabIndex: _feedTabIndex,
          visible: true,
        );
  }

  Future<void> _seedNotificationDoc({
    required String type,
    required String title,
    required String message,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showDebugSnack('No logged-in user, cannot seed notifications.');
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .add({
          'type': type,
          'title': title,
          'message': message,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'profileImageUrl': '',
          'eventId': 'debug-event-1',
        });

    _markFeedBadgeForDebug();

    _showDebugSnack('Seeded $type notification doc.');
  }

  Future<void> _seedFollowNotificationDoc() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showDebugSnack('No logged-in user, cannot seed notifications.');
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('followRequests')
        .add({
          'userID': 'debug-user',
          'username': 'Debug User',
          'profileImageUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
        });

    _markFeedBadgeForDebug();

    _showDebugSnack('Seeded follow notification doc.');
  }

  Future<void> _seedFirestoreNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No logged-in user, cannot seed notifications.'),
        ),
      );
      return;
    }

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    await userDoc.collection('notifications').add({
      'type': 'join',
      'title': 'Debug Notification',
      'message': 'Seeded from debug panel',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'profileImageUrl': '',
      'eventId': 'debug-event-1',
    });

    await userDoc.collection('followRequests').add({
      'userID': 'debug-user',
      'username': 'Debug User',
      'profileImageUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _markFeedBadgeForDebug();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug notification docs created.')),
    );
  }

  void _goBranch(int index) {
    // Eğer şu an Home'daysak (2) VE tekrar Home'a (2) basıldıysa...
    if (widget.navigationShell.currentIndex == 0 && index == 0) {
      // GetIt'teki sinyali tetikle (Sayıyı arttır)
      // Bu sinyal HomeContentPage'deki dinleyiciyi çalıştıracak.
      getIt<ValueNotifier<int>>(instanceName: 'homeScrollTrigger').value++;
    } else {
      // Diğer durumlar için standart GoRouter geçişi yap
      widget.navigationShell.goBranch(
        index,
        initialLocation: index == widget.navigationShell.currentIndex,
      );
      final NavBarActiveIndexNotifier navBarActiveIndexNotifier = ref.read(
        navBarActiveIndexProvider.notifier,
      );
      navBarActiveIndexNotifier.setIndex(index);

      // User opened the tab, so we can clear its red-dot indicator.
      ref.read(navBarBadgeProvider).clearBadge(index);
    }
  }

  Widget _buildNavIcon({required IconData icon, required bool showBadge}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 25),
        if (showBadge)
          const Positioned(
            right: -1,
            top: -2,
            child: _NavDot(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.watch(navBarBadgeStateProvider);
    final navBadgeService = ref.read(navBarBadgeProvider);
    return Scaffold(
      body: widget.navigationShell,
      floatingActionButton: kDebugMode
          ? const Padding(
              padding: EdgeInsets.only(top: 56),
              child: DebugPanel(),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Gölge rengi
              blurRadius: 15, // Yayılma yumuşaklığı
              spreadRadius: 2, // Gölgenin büyüklüğü
              offset: const Offset(0, -2), // Gölgeyi yukarı doğru (-y) kaydırır
            ),
          ],

          border: const Border(),
        ),
        child: BottomNavigationBar(
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _goBranch,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedItemColor: theme.colorScheme.tertiary,
          unselectedItemColor: theme.textTheme.bodyMedium?.color?.withOpacity(
            0.5,
          ),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 50,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                icon: Icons.home_outlined,
                showBadge: navBadgeService.hasBadge(0),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                icon: Icons.search,
                showBadge: navBadgeService.hasBadge(1),
              ),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                icon: Icons.map_outlined,
                showBadge: navBadgeService.hasBadge(2),
              ),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                icon: Icons.chat_bubble_outline,
                showBadge: navBadgeService.hasBadge(_chatTabIndex),
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                icon: Icons.person_outline,
                showBadge: navBadgeService.hasBadge(4),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavDot extends StatelessWidget {
  const _NavDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.2),
      ),
    );
  }
}
