import 'dart:async';

import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/providers/inbox_notification_providers.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/domain/repositories/inbox_repository.dart';
import 'package:outnest/presentation/notification/view/components/notification_tile.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_executor.dart';
import 'package:outnest/presentation/notification/view/components/strategies/action/notification_tile_action_factory.dart';
import 'package:outnest/presentation/notification/view/components/strategies/notification_tile_composition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({
    this.composition,
    super.key,
  });

  final NotificationTileComposition? composition;

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  late final InboxRepository _inboxRepository;
  final NotificationTileActionExecutor _actionExecutor =
      NotificationTileActionExecutor();
  late final NotificationTileComposition _composition;

  @override
  void initState() {
    super.initState();
    _inboxRepository = getIt<InboxRepository>();
    unawaited(_inboxRepository.markAllNotificationsRead());
    _composition =
        widget.composition ??
        NotificationTileComposition(
          actionFactory: NotificationTileActionFactory(),
        );
  }

  Future<void> _onNotificationTap(NotificationEntity notification) async {
    final actionConfig = _composition.buildAction(notification, ref);
    if (actionConfig == null) return;
    await _actionExecutor.execute(context, actionConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Symbols.reply,
            color: Colors.black,
            size: 24.sp,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Bildirimler',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w700,
            fontSize: 18.sp, // Figma standardı
            color: Colors.black,
          ),
        ),
        actions: [
          // --- TAKİP İSTEKLERİ İKONU ---
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: GestureDetector(
              onTap: () async {
                await context.push('/follow-requests');
                if (!mounted) return;
                unawaited(
                  ref.read(unreadFollowRequestsProvider.notifier).refresh(),
                );
              },
              child: SizedBox(
                width: 32.w,
                height: 32.w,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Center(
                      child: Icon(
                        Symbols.person_add,
                        color: Colors.black,
                        size: 26,
                      ),
                    ),
                    // Bildirim Sayısı Badge
                    if (ref.watch(unreadFollowRequestsProvider))
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            color: AppColors.darkPrimaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ref
          .watch(notificationStreamProvider)
          .when(
            data: (notifications) {
              if (notifications.isEmpty) {
                return const Center(child: Text('Bildirim yok'));
              }

              final now = DateTime.now();
              final today = <NotificationEntity>[];
              final others = <NotificationEntity>[];

              for (var n in notifications) {
                final diff = now.difference(n.createdAt);
                if (diff.inHours < 24) {
                  today.add(n);
                } else {
                  others.add(n);
                }
              }

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (today.isNotEmpty) ...[
                    _buildSectionHeader('Bugün'),
                    ...today.map(
                      (n) => NotificationTile(
                        notification: n,
                        composition: _composition,
                        onTap: () => _onNotificationTap(n),
                      ),
                    ),
                  ],
                  if (others.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    _buildSectionHeader('Son 7 Gün'),
                    ...others.map(
                      (n) => NotificationTile(
                        notification: n,
                        composition: _composition,
                        onTap: () => _onNotificationTap(n),
                      ),
                    ),
                  ],
                  SizedBox(height: 20.h),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Bildirimler yüklenemedi')),
          ),
    );
  }

  // Başlık Stili
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, top: 16.h, bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
