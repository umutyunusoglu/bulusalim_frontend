import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/notification/follow_notification_entity.dart';
import 'package:outnest/domain/repositories/inbox_repository.dart';
import 'package:outnest/presentation/notification/view/components/follow_request_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class FollowRequestsPage extends StatefulWidget {
  const FollowRequestsPage({super.key});

  @override
  State<FollowRequestsPage> createState() => _FollowRequestsPageState();
}

class _FollowRequestsPageState extends State<FollowRequestsPage> {
  late final InboxRepository _inboxRepository;

  @override
  void initState() {
    super.initState();
    _inboxRepository = getIt<InboxRepository>();
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
      body: StreamBuilder<List<FollowNotificationEntity>>(
        stream: _inboxRepository.getFollowRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // En güncel ID'yi al ve okunmamışları "okundu" yap
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final latestId = snapshot.data!.first.userID;

            _inboxRepository.updateFollowNotificationRead(latestId);
          }
          final items = snapshot.data ?? [];
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

              if (older.isNotEmpty) ...[
                SizedBox(height: 10.h),
                _buildSectionHeader('Son 7 Gün'),
                ...older.map((item) => FollowRequestTile(item: item)),
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
