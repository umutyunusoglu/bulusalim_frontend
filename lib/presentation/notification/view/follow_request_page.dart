import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outnest/application/providers/inbox_notification_providers.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/notification/follow_notification_entity.dart';
import 'package:outnest/presentation/notification/view/components/follow_request_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class FollowRequestsPage extends ConsumerStatefulWidget {
  const FollowRequestsPage({super.key});

  @override
  ConsumerState<FollowRequestsPage> createState() => _FollowRequestsPageState();
}

class _FollowRequestsPageState extends ConsumerState<FollowRequestsPage> {
  bool _didInitialMark = false;
  bool _isMarkingSeen = false;

  Future<void> _markAsSeen(List<FollowNotificationEntity> items) async {
    if (_isMarkingSeen || items.isEmpty) return;
    _isMarkingSeen = true;
    try {
      // ref.read'leri await'ten ÖNCE yap, referansları sakla
      final repository = ref.read(inboxRepositoryProvider);
      final notifier = ref.read(unreadFollowRequestsProvider.notifier);

      await repository.markFollowRequestsAsSeen(items.first.userID);

      // İkinci await'ten önce hâlâ mounted mıyız kontrol et
      if (!mounted) return;
      await notifier.refresh();
    } finally {
      _isMarkingSeen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final followRequestsAsync = ref.watch(followRequestsStreamProvider);

    ref.listen<AsyncValue<List<FollowNotificationEntity>>>(
      followRequestsStreamProvider,
      (previous, next) {
        final items = next.asData?.value;
        if (items == null || items.isEmpty) return;
        unawaited(_markAsSeen(items));
      },
    );

    if (!_didInitialMark) {
      final items = followRequestsAsync.asData?.value;
      if (items != null && items.isNotEmpty) {
        _didInitialMark = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(_markAsSeen(items));
        });
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Bildirimler',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
            color: Colors.black,
          ),
        ),
      ),
      body: followRequestsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Takip isteği yok'));
          }
          final now = DateTime.now();

          // 3 Ayrı Sepet Oluşturuyoruz
          final today = <FollowNotificationEntity>[];
          final lastWeek = <FollowNotificationEntity>[];
          final older = <FollowNotificationEntity>[];

          for (var item in items) {
            // 1. Timezone güvenliği için local saate çevir
            final date = item.createdAt.toLocal();

            // 2. Takvim günü kontrolü (Bugün mü?)
            final isToday =
                date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;

            if (isToday) {
              today.add(item);
            } else {
              // Bugün değilse, farka bak
              final diff = now.difference(date);

              if (diff.inDays <= 7) {
                lastWeek.add(item); // Son 7 gün (Bugün hariç)
              } else {
                older.add(item); // 7 günden eski
              }
            }
          }
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // MAVİ BAŞLIK
              Padding(
                padding: EdgeInsets.only(left: 16.w, top: 10.h, bottom: 5.h),
                child: Text(
                  'Takip İstekleri',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.tertiaryColor,
                  ),
                ),
              ),

              if (today.isNotEmpty) ...[
                _buildSectionHeader('Bugün'),
                ...today.map((item) => FollowRequestTile(item: item)),
              ],

              if (lastWeek.isNotEmpty) ...[
                SizedBox(height: 10.h),
                _buildSectionHeader('Son 7 Gün'),
                ...lastWeek.map((item) => FollowRequestTile(item: item)),
              ],

              if (older.isNotEmpty) ...[
                SizedBox(height: 10.h),
                _buildSectionHeader('Daha Eski'),
                // Demo amaçlı tekrar gösteriyoruz
                ...older.map((item) => FollowRequestTile(item: item)),
              ],
              SizedBox(height: 20.h),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Takip istekleri yüklenemedi')),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, top: 16.h, bottom: 4.h),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}
