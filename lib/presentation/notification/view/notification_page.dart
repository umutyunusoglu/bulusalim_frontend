import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/notification/notification_entity.dart';
import 'package:outnest/domain/repositories/inbox_repository.dart';
import 'package:outnest/presentation/notification/view/components/notification_tile.dart';
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
    // Buraya bildirim detayına gitme mantığı eklenebilir
    final type = notification.type;
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
                        Symbols.person_add,
                        color: Colors.black,
                        size: 26,
                      ),
                    ),
                    // Bildirim Sayısı Badge
                    FutureBuilder<bool>(
                      future: _inboxRepository.hasUnreadFollowRequest(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }

                        final hasUnread = snapshot.data ?? false;
                        if (!hasUnread) return const SizedBox.shrink();

                        return Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10.w, // Küçük, şık bir nokta boyutu
                            height: 10.w,
                            decoration: BoxDecoration(
                              color: AppColors.darkPrimaryColor,
                              shape: BoxShape.circle,
                              // İkonun üzerinde daha "temiz" durması için beyaz bir çerçeve
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
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
            return const Center(child: Text('Bildirim yok'));
          }

          // --- GRUPLAMA MANTIĞI ---
          final now = DateTime.now();

          // Yöntem 1: Tek döngü ile ayırma (En Performanslısı)
          // Listeyi bir kere döner ve ikiye ayırır.
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
