import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/domain/entities/notification/notification_entity.dart';
import 'package:bulusalim/domain/repositories/inbox_repository.dart';
import 'package:bulusalim/screens/notification/notification_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late final InboxRepository _inboxRepository;

  @override
  void initState() {
    super.initState();
    _inboxRepository = getIt<InboxRepository>();
  }

  void _onNotificationTap(NotificationEntity notification) {
    _inboxRepository.markAsRead(notification.id);
    // Buraya bildirim detayına gitme mantığı eklenebilir
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
            fontSize: 18.sp, // Figma standardı
            color: Colors.black,
          ),
        ),
        actions: [
          // --- TAKİP İSTEKLERİ İKONU ---
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: GestureDetector(
              onTap: () {
                context.push('/follow-requests');
              },
              child: SizedBox(
                width: 32.w,
                height: 32.w,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.person_add_alt_outlined,
                        color: Colors.black,
                        size: 26,
                      ),
                    ),
                    // Bildirim Sayısı Badge
                    StreamBuilder<int>(
                      stream: _inboxRepository.getUnreadCountStream(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count <= 0) return const SizedBox();

                        return Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            constraints: BoxConstraints(
                              minWidth: 16.w,
                              minHeight: 16.w,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.salmonPink,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                count > 99 ? '99+' : count.toString(),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationEntity>>(
        stream: _inboxRepository.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(child: Text("Bildirim yok"));
          }

          // --- GRUPLAMA MANTIĞI ---
          final now = DateTime.now();
          final today = notifications.where((n) {
            final diff = now.difference(n.createdAt);
            // Son 24 saat içindeyse "Bugün" kabul ediyoruz
            return diff.inHours < 24;
          }).toList();

          final others = notifications
              .where((n) => !today.contains(n))
              .toList();

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // BUGÜN LİSTESİ
              if (today.isNotEmpty) ...[
                _buildSectionHeader('Bugün'),
                ...today.map(
                  (n) => NotificationTile(
                    notification: n,
                    onTap: () => _onNotificationTap(n),
                  ),
                ),
              ],

              // ESKİLER LİSTESİ
              if (others.isNotEmpty) ...[
                SizedBox(height: 10.h),
                _buildSectionHeader('Son 7 Gün'),
                ...others.map(
                  (n) => NotificationTile(
                    notification: n,
                    onTap: () => _onNotificationTap(n),
                  ),
                ),
              ],
              SizedBox(height: 20.h),
            ],
          );
        },
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
