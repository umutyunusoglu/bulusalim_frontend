import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_badges_provider.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_event_providers.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/application/providers/badges/all_badges_provider.dart';
import 'package:outnest/application/providers/navbar_badge_provider.dart';
import 'package:outnest/application/service_locators/event_verification_service_provider.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';

class DebugPanel extends ConsumerWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) return const SizedBox.shrink();

    return FloatingActionButton.small(
      heroTag: 'debugPanel',
      tooltip: 'Debug Panel',
      onPressed: () => _openPanel(context, ref),
      child: const Icon(Icons.bug_report_outlined, size: 18),
    );
  }

  void _openPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _DebugPanelSheet(
        parentContext: context,
        ref: ref,
      ),
    );
  }
}

class _DebugPanelSheet extends ConsumerWidget {
  _DebugPanelSheet({
    required this.parentContext,
    required this.ref,
  });

  final BuildContext parentContext;
  final WidgetRef ref;

  static const int _feedTabIndex = 0;

  final LoggingService _logger = getIt<LoggingService>();
  void _showDebugSnack(String text) {
    if (!parentContext.mounted) return;
    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  void _markFeedBadge() {
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

    _markFeedBadge();
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

    _markFeedBadge();
    _showDebugSnack('Seeded follow notification doc.');
  }

  Future<void> _seedFirestoreNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showDebugSnack('No logged-in user, cannot seed notifications.');
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

    _markFeedBadge();
    _showDebugSnack('Debug notification docs created.');
  }

  void _showEventPickerDialog(BuildContext context) {
    final ongoingEvents = ref.read(ongoingEventsProvider).value ?? [];

    if (ongoingEvents.isEmpty) {
      _showDebugSnack('Ongoing event bulunamadı.');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Event Seç'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ongoingEvents.length,
            itemBuilder: (_, index) {
              final event = ongoingEvents[index];
              return ListTile(
                title: Text(event.name),
                subtitle: Text(event.eventID),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _verifyEvent(event);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyEvent(EventEntity event) async {
    try {
      final verificationService = ref.read(eventVerificationServiceProvider);
      await verificationService.markEventAsVerifiedForDebug(event);
      _showDebugSnack('${event.name} verified edildi.');
    } catch (e) {
      _showDebugSnack('Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Panel',
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
              leading: const Icon(Icons.add_alert_outlined),
              title: const Text('Seed Firestore: invite notification'),
              onTap: () async {
                Navigator.pop(context);
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
                Navigator.pop(context);
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
                Navigator.pop(context);
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
                Navigator.pop(context);
                await _seedFirestoreNotifications();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open /notifications'),
              onTap: () {
                Navigator.pop(context);
                parentContext.push('/notifications');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open /follow-requests'),
              onTap: () {
                Navigator.pop(context);
                parentContext.push('/follow-requests');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.clear),
              title: const Text('Clear chat badge'),
              onTap: () {
                Navigator.pop(context);
                ref.read(navBarBadgeProvider).clearBadge(3);
              },
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified_outlined),
              title: const Text('Manuel Verification'),
              subtitle: const Text('Ongoing event seç ve verify et'),
              onTap: () {
                Navigator.pop(context);
                _showEventPickerDialog(parentContext);
              },
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Log: allBadgesProvider'),
              onTap: () async {
                Navigator.pop(context);
                final result = await ref.read(allBadgesProvider.future);
                _logger.debug(
                  'allBadgesProvider (${result.length} items): ${result.map((b) => b.toString()).join(', ')}',
                );
                _showDebugSnack('allBadges: ${result.length} badge loglandı.');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Log: currentUserBadgesProvider'),
              onTap: () async {
                Navigator.pop(context);
                final result = await ref.read(currentUserBadgesProvider.future);
                _logger.debug(
                  'currentUserBadgesProvider (${result.length} items): ${result.map((b) => b.toString()).join(', ')}',
                );
                _showDebugSnack(
                  'currentUserBadges: ${result.length} badge loglandı.',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
