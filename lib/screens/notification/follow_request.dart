import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/domain/entities/notification/follow_notification_entity.dart';
import 'package:bulusalim/domain/repositories/inbox_repository.dart';
import 'package:bulusalim/screens/notification/follow_request_tile.dart';
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              color: Colors.black,
              size: 24.sp,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<FollowNotificationEntity>>(
        stream: _inboxRepository.getFollowRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty)
            return const Center(child: Text("Takip isteği yok"));

          // GRUPLAMA MANTIĞI
          final now = DateTime.now();
          final today = items.where((n) {
            final diff = now.difference(n.createdAt);
            return diff.inHours < 24 && now.day == n.createdAt.day;
          }).toList();

          final others = items.where((n) => !today.contains(n)).toList();

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

              if (others.isNotEmpty) ...[
                SizedBox(height: 10.h),
                _buildSectionHeader('Son 7 Gün'),
                ...others.map((item) => FollowRequestTile(item: item)),
              ],

              if (others.isNotEmpty) ...[
                SizedBox(height: 10.h),
                _buildSectionHeader('Daha Eski'),
                // Demo amaçlı tekrar gösteriyoruz
                ...others.map((item) => FollowRequestTile(item: item)),
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
