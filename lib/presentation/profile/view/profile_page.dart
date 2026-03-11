import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/profile_segment_enum.dart';
import 'package:outnest/core/utils/types/enums/user_event_status_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/friend_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/analytics/event_configs/select_profile_segment_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/send_event_invitation_analytics_config.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/session_state.dart';
import 'package:outnest/domain/usecases/send_event_invitation_usecase.dart';
import 'package:outnest/presentation/home/view/components/post/small_stacked_avatars.dart';
import 'package:outnest/presentation/profile/view/components/announcement_button.dart';
import 'package:outnest/presentation/profile/view/components/dump_tab.dart';
import 'package:outnest/presentation/profile/view/components/events_tab.dart';
import 'package:outnest/presentation/profile/view/components/grid_tab.dart';
import 'package:outnest/presentation/profile/view/components/private_account_view.dart';
import 'package:outnest/presentation/profile/view/components/profile_photo.dart';
import 'package:outnest/presentation/profile/view/components/profile_tab_bar.dart';
import 'package:outnest/presentation/profile/view/follows_page.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';
import 'package:outnest/presentation/shared/login_button.dart';
import 'package:outnest/presentation/shared/popup.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.profileUserID, super.key});

  final String profileUserID;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int numberOfEvents = 0;
  int numberOfFollowers = 0;
  int numberOfFollowing = 0;

  String _profileImageUrl = '';
  final List<String> _badges = [
    'assets/badge/badge1.png',
    'assets/badge/badge2.png',
    'assets/badge/badge3.png',
  ];

  String _bio = '';
  List<EventEntity> _consideredEvents = [];
  List<EventEntity> _currentEvents = [];
  List<CompactUserEntity> _commonFollowers = [];

  StreamSubscription<List<PostEntity>>? _postsSubscription;

  String _fullName = '';
  bool _isFollowing = false;
  bool _hasSentFollowRequest = false;
  bool _isLoadingEvents = true;
  bool _isPrivateAccount = false;
  final PageController _pageController = PageController();

  List<PostEntity> _pinnedPosts = [];
  List<PostEntity> _activePosts = [];

  String _school = '';
  int _selectedTabIndex = 0;
  String _username = '';

  @override
  void dispose() {
    _pageController.dispose();
    _postsSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initPostStream();
    _fetchProfileData();
  }

  void _navigateToFollows(BuildContext context, int initialTab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowsPage(
          profileUserID: widget.profileUserID,
          username: _username,
          initialTabIndex: 0,
          followerCount: numberOfFollowers,
          followingCount: numberOfFollowing,
        ),
      ),
    );
  }

  void _initPostStream() {
    final userRepository = getIt<UserRepository>();

    // Aboneliği başlatıyoruz
    _postsSubscription = userRepository
        .getUserPostsStream(widget.profileUserID)
        .listen(
          (allPosts) {
            // STREAM TETİKLENDİĞİNDE BURASI ÇALIŞIR
            // (Biri post sildiğinde, yeni post attığında veya pinlediğinde)

            if (!mounted) return;

            // 1. Pinli ve Aktif ayrımını yap
            final pinned = allPosts.where((p) => p.isPinned).toList();
            final active = allPosts.where((p) => !p.isPinned).toList();

            // 2. Aktifleri tarihe göre sırala (Yeniden eskiye)
            active.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            // 3. UI'ı güncelle
            setState(() {
              _pinnedPosts = pinned;
              _activePosts = active;
            });
          },
          onError: (error) {
            // Hata yönetimi
            if (mounted) {
              debugPrint('Post Stream Hatası: $error');
            }
          },
        );
  }

  void _handlePinStatusChange(String postId, bool isPinned) {
    setState(() {
      PostEntity? targetPost;

      // 1. Postu mevcut listesinden bul ve çıkar
      final pinnedIndex = _pinnedPosts.indexWhere((p) => p.postID == postId);
      if (pinnedIndex != -1) {
        targetPost = _pinnedPosts.removeAt(pinnedIndex);
      } else {
        final activeIndex = _activePosts.indexWhere((p) => p.postID == postId);
        if (activeIndex != -1) {
          targetPost = _activePosts.removeAt(activeIndex);
        }
      }

      if (targetPost == null) return; // Post bulunamazsa çık

      // 2. Postun durumunu güncelle (Yeni bir entity kopyası oluşturuyoruz)
      // Not: Entity'nizde copyWith varsa onu kullanın, yoksa manuel oluşturun:
      final updatedPost = targetPost.copyWith(isPinned: isPinned);

      // 3. Postu yeni listesine ekle
      if (isPinned) {
        // Pinlenenler listesinin başına ekle
        _pinnedPosts.insert(0, updatedPost);
      } else {
        // Aktifler listesine ekle ve tarihe göre yeniden sırala
        _activePosts
          ..add(updatedPost)
          ..sort((a, b) => b!.createdAt.compareTo(a!.createdAt));
      }
    });
  }

  Future<void> _fetchProfileData() async {
    if (!mounted) return;

    try {
      final userRepository = getIt<UserRepository>();
      final eventRepository = getIt<EventRepository>();

      var user;

      if (widget.profileUserID == getIt<SessionService>().currentUser?.userID) {
        user = getIt<SessionService>().currentUser;
      } else {
        getIt<LoggingService>().debug("Others profi");
        user = await userRepository.getUserPublicData(widget.profileUserID);
      }

      final userEventsEnrolled = await userRepository.getUserEventLog(
        widget.profileUserID,
      );

      final enrolledEventIds = <Identifier>[];
      final savedEventIds = <Identifier>[];

      for (final event in userEventsEnrolled) {
        switch (event.status) {
          case UserEventStatusEnum.upcoming:
            enrolledEventIds.add(event.eventId);
          case UserEventStatusEnum.ongoing:
            enrolledEventIds.add(event.eventId);
          case UserEventStatusEnum.saved:
            savedEventIds.add(event.eventId);
          case UserEventStatusEnum.completed:
            numberOfEvents += 1;
          default:
            break;
        }
      }

      final sessionService = getIt<SessionService>();
      var isFollowing = false;
      final currentUser = sessionService.currentUser;
      final sessionState = sessionService.currentState;
      final myFollowers = sessionState.followers;

      final commonFollows = <CompactUserEntity>[];

      //Todo: optimize

      if (widget.profileUserID != currentUser?.userID) {
        for (final follower in myFollowers) {
          final isFollowing = await userRepository.isFollowing(
            widget.profileUserID,
            follower.userID,
          );
          if (isFollowing) {
            commonFollows.add(follower);
          }
        }
      }

      if (user!.userID == currentUser?.userID) {
        isFollowing = true;
      } else {
        isFollowing = await userRepository.isFollowing(
          currentUser!.userID,
          user.userID as Identifier,
        );
      }

      var hasSentFollowRequest = false;
      if (!isFollowing) {
        hasSentFollowRequest = await userRepository.hasSentFollowRequest(
          currentUser!.userID,
          user.userID as Identifier,
        );
      }

      var enrolledEvents = <EventEntity>[];
      if (enrolledEventIds.isNotEmpty) {
        enrolledEvents = await eventRepository.getEventsByIds(enrolledEventIds);
      }

      var savedEvents = <EventEntity>[];
      if (savedEventIds.isNotEmpty) {
        savedEvents = await eventRepository.getEventsByIds(savedEventIds);
      }

      final followerCount = await userRepository.getFollowersCount(
        widget.profileUserID,
      );
      final followeeCount = await userRepository.getFolloweesCount(
        widget.profileUserID,
      );
      final completedEventCount = await userRepository.getCompletedEventCount(
        widget.profileUserID,
      );

      final isPrivate = user.isPrivate;

      if (!mounted) return;

      getIt<LoggingService>().debug("Profile data fetched: $user");

      setState(() {
        // dynamic olduğu için [] operatörü veya nokta operatörü kullanılabilir
        // null check (?.) ve null-coalescing (??) ile güvenliğe alıyoruz
        _username = (user.username ?? '').toString();
        _fullName = (user.nameSurname ?? '').toString();
        _bio = (user.bio ?? '').toString();
        _school = (user.university ?? 'Üniversite Doğrulanmadı').toString();
        _profileImageUrl = (user.profileImageUrl ?? '').toString();

        // Boolean değerler için 'is' kontrolü eklemek dynamic tipte hayat kurtarır
        _isFollowing = isFollowing == true;
        _isPrivateAccount = isPrivate == true;
        _hasSentFollowRequest = hasSentFollowRequest == true;

        // Sayısal verilerde hata almamak için 0'a yuvarlıyoruz
        numberOfFollowers = followerCount ?? 0;
        numberOfFollowing = followeeCount ?? 0;
        numberOfEvents = completedEventCount ?? 0;

        _commonFollowers = commonFollows ?? [];
        _currentEvents = enrolledEvents ?? [];
        _consideredEvents = savedEvents ?? [];

        _isLoadingEvents = false;
      });
    } catch (e) {
      getIt<LoggingService>().error(
        'Profil verisi alınırken hata oluştu $e',
      );
      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
        });
      }
    }
  }

  Future<void> _sendFollowRequest() async {
    final userRepository = getIt<UserRepository>();
    final sessionService = getIt<SessionService>();
    final currentUser = sessionService.currentUser;
    if (currentUser == null) return;

    setState(() => _hasSentFollowRequest = !_hasSentFollowRequest);

    try {
      if (_hasSentFollowRequest) {
        await userRepository.sendFollowRequest(
          currentUser.userID,
          widget.profileUserID,
          false,
        );
      } else {
        await userRepository.cancelFollowRequest(
          currentUser.userID,
          widget.profileUserID,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasSentFollowRequest = !_hasSentFollowRequest);
      }
    }
  }

  Future<void> _toggleFollow() async {
    final userRepository = getIt<UserRepository>();
    final sessionService = getIt<SessionService>();
    final currentUser = sessionService.currentUser;
    if (currentUser == null) return;

    // SessionState üzerinden anlık duruma bakıyoruz
    final isCurrentlyFollowing = sessionService.currentState.followees.any(
      (f) => f.userID == widget.profileUserID,
    );

    try {
      if (!isCurrentlyFollowing) {
        // TAKİP ETME İŞLEMİ
        final me = Follower(
          userID: currentUser.userID,
          username: currentUser.username,
          profileImageUrl: currentUser.profileImageUrl,
          createdAt: DateTime.now(),
        );
        final target = Followee(
          userID: widget.profileUserID,
          username: _username,
          profileImageUrl: _profileImageUrl,
          createdAt: DateTime.now(),
        );

        await userRepository.addFollowee(currentUser.userID, target);
        await userRepository.addFollower(widget.profileUserID, me);
      } else {
        // TAKİBİ BIRAKMA İŞLEMİ
        await userRepository.removeFollowee(
          currentUser.userID,
          widget.profileUserID,
        );
        await userRepository.removeFollower(
          widget.profileUserID,
          currentUser.userID,
        );
      }

      // BU KOD BÜTÜN UYGULAMAYI ANINDA GÜNCELLER (Profil sayfası dahil)
      await sessionService.refreshSession();
    } catch (e) {
      debugPrint("Takip işlemi başarısız: $e");

      showErrorPopup(
        context,
        message: 'İşlem başarısız oldu, lütfen tekrar deneyin.',
      );
    }
  }

  // --- TAKİBİ BIRAKMA DIALOGU ---
  void _showUnfollowDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Popup(
        title:
            '$_username hesabını takip etmeyi bırakmak istediğine emin misin?',
        description:
            'Bu hesabı tekrardan takip etmek için istek tekrardan göndermen gerekecek.',
        confirmButtonText: 'takibi bırak',
        confirmButtonColor: const Color(0xFF5D6B82),
        onConfirm: () {
          context.pop();
          _toggleFollow();
        },
      ),
    );
  }

  // --- 1. ETKİNLİK YOKSA (HATA POPUP) ---
  void _showNoShareableEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 10.0,
        shadowColor: Colors.black.withOpacity(0.3),
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Paylaşabileceğin aktif bir buluşman yok. Yeni bir tane oluşturmaya ne dersin?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.tertiaryColor,
                ),
              ),

              SizedBox(height: 12.h),

              Text(
                'Buluşma paylaşabilmek için diğer buluşma oluştur ya da diğer kullanıcıların kurdukları buluşmalara katıl.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8E8E93),
                  height: 1.4,
                ),
              ),

              SizedBox(height: 25.h),

              // BULUŞMA OLUŞTUR BUTONU
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // 1. Popup'ı kapat
                    Navigator.pop(context);
                    // 2. yönlendirme kodunu çalıştır
                    context.go('/map', extra: true);
                  },
                  borderRadius: BorderRadius.circular(30.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // İkonlu Yuvarlak Alan
                        Container(
                          width: 50.w,
                          height: 50.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add_location_alt_outlined,
                            color: const Color(0xFF2E7D32),
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Buluşma Oluştur',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. ETKİNLİK VARSA (SEÇİM POPUP) ---
  Future<void> _showShareSelectionDialog(
    BuildContext context,
    List<EventEntity> events,
  ) async {
    var selectedIndex = 0;

    final eventRepository = getIt<EventRepository>();

    // 1. Asenkron filtreleme burada yapılır
    var validEvents = <EventEntity>[];
    for (var e in events) {
      final hasSent = await eventRepository.hasSentInvitation(
        e,
        widget.profileUserID,
      );
      if (!hasSent) {
        validEvents.add(e);
      }
    }

    if (validEvents.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy, size: 48.r, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  'Paylaşılacak Buluşma Bulunamadı',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                if (events.isEmpty)
                  Text(
                    'Henüz aktif bir buluşman bulunmuyor. Önce bir buluşma oluşturmalısın.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                if (events.isNotEmpty)
                  Text(
                    'Tüm aktif buluşmalarına zaten davet gönderdin. Yeni davetler gönderebilmek için yeni buluşmalar kurabilir veya mevcut buluşmalarına yeni katılımcılar ekleyebilirsin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                    child: Text('tamam', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return; // Fonksiyonun geri kalanını çalıştırma
    }
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 24.h,
                  horizontal: 16.w,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // BAŞLIK
                    Text(
                      '@$_username kullanıcısı ile paylaşacağın buluşmayı seç',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // CAROUSEL
                    SizedBox(
                      height: 100.h,
                      child: PageView.builder(
                        itemCount: validEvents.length,
                        onPageChanged: (index) {
                          setState(() => selectedIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final event = events[index] as EventEntity;
                          (event.name ?? 'Buluşma ${index + 1}');

                          // 1. URL'nin tipini kontrol et (Network mü Asset mi?)
                          final imageUrl = event.creator.profileImageUrl;

                          final isNetwork = imageUrl.startsWith('http');

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24.r,
                                backgroundColor: Colors.grey.shade200,
                                // 2. Duruma göre doğru Provider'ı seç
                                backgroundImage: isNetwork
                                    ? CachedNetworkImageProvider(
                                        fixEmulatorUrl(imageUrl),
                                      )
                                    : AssetImage(
                                            FileService.defaultProfileImageUrl(),
                                          )
                                          as ImageProvider,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                event.name ?? 'Buluşma ${index + 1}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // NOKTALAR (DOTS)
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(validEvents.length, (index) {
                        return Container(
                          width: 5.w,
                          height: 5.w,
                          margin: EdgeInsets.symmetric(horizontal: 2.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectedIndex == index
                                ? AppColors.primaryColor
                                : Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 20.h),

                    // BUTONLAR
                    Row(
                      children: [
                        // VAZGEÇ
                        Expanded(
                          child: TextButton(
                            onPressed: () => context.pop(),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF2F2F7),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                            ),
                            child: Text(
                              'vazgeç',
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),

                        // PAYLAŞ
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final event =
                                  events[selectedIndex] as EventEntity;

                              // 1. Kullanıcıya işlemin başladığını hissettir (Opsiyonel: Dialog'u kapatmadan önce loading gösterilebilir)
                              // Şimdilik pop yapıp ana ekranda Snackbar gösterelim.

                              final navigator = Navigator.of(context);

                              navigator
                                  .pop(); // Önce BottomSheet veya Dialog'u kapatıyoruz

                              try {
                                // 2. Fonksiyonu await ile bekle
                                final resultMessage =
                                    await getIt<SendEventInvitation>().call(
                                      toID: widget.profileUserID,
                                      toUsername: _username,
                                      toprofileImageUrl: _profileImageUrl,
                                      eventID: event.eventID,
                                      eventName: event.name ?? '',
                                    );

                                // 3. Başarılı durum bildirimi
                                showInfoPopup(
                                  context,
                                  message: 'Davet başarıyla gönderildi!',
                                );

                                getIt<AnalyticsService>()
                                    .logSendEventInvitation(
                                      SendEventInvitationAnalyticsConfig(
                                        eventID: event.eventID,
                                        toUserID: widget.profileUserID,
                                      ),
                                    );

                                debugPrint(
                                  'Buluşma paylaşıldı: ${event.name}',
                                );
                              } on Exception catch (e) {
                                // 4. Hata durum bildirimi
                                showErrorPopup(
                                  context,
                                  message:
                                      'Davet gönderilemedi, lütfen tekrar deneyin.',
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                            ),
                            child: Text(
                              'paylaş',
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- DUYURU BUTONU TIKLANINCA ÇALIŞACAK MANTIK ---
  void _handleAnnouncementPress() {
    final sessionService = getIt<SessionService>();
    final currentUser = sessionService.currentUser;

    if (currentUser == null) return;

    // Aktif buluşmaleri al
    final activeEvents =
        sessionService.currentState.ongoingEvents +
        sessionService.currentState.upcomingEvents;

    if (activeEvents.isEmpty) {
      // 0 buluşma -> Hata Mesajı
      _showNoShareableEventDialog(context);
    } else {
      // 1 veya Daha Fazla buluşma -> Seçim/Paylaşım Dialogu
      _showShareSelectionDialog(context, activeEvents);
    }
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTabIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    getIt<AnalyticsService>().logSelectProfileSegment(
      SelectProfileSegmentAnalyticsConfig(
        segment: ProfileSegmentEnum.values[index],
      ),
    );
  }

  // HEADER ALANI
  // HEADER ALANI
  Widget _buildProfileHeader(BuildContext context, SessionState state) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final onSurface = theme.colorScheme.onSurface;

    final sessionUser = state.user;
    final isCurrentUser = widget.profileUserID == sessionUser?.userID;

    // --- 1. ANLIK TAKİP DURUMUNU YAKALA (Global State'den) ---
    // Eğer kendi listemizde (başka bir sayfada) takipten çıkarsak, bu değer ANINDA false olur!
    final isCurrentlyFollowing =
        isCurrentUser ||
        state.followees.any((f) => f.userID == widget.profileUserID);

    // --- 2. DİNAMİK TAKİPÇİ SAYISI ---
    var displayFollowerCount = isCurrentUser
        ? state.followers.length
        : numberOfFollowers;
    var displayFollowingCount = isCurrentUser
        ? state.followees.length
        : numberOfFollowing;

    if (!isCurrentUser) {
      if (_isFollowing && !isCurrentlyFollowing) {
        displayFollowerCount = (numberOfFollowers - 1) < 0
            ? 0
            : (numberOfFollowers - 1);
      } else if (!_isFollowing && isCurrentlyFollowing) {
        displayFollowerCount = numberOfFollowers + 1;
      }

      if (_isFollowing && !isCurrentlyFollowing) {
        displayFollowingCount = (numberOfFollowing - 1).clamp(
          0,
          numberOfFollowing,
        );
      } else if (!_isFollowing && isCurrentlyFollowing) {
        displayFollowingCount = numberOfFollowing + 1;
      }
    }

    final currentUsername = isCurrentUser
        ? (sessionUser?.username ?? '')
        : _username;
    final currentFullName = isCurrentUser
        ? (sessionUser?.nameSurname ?? '')
        : _fullName;
    final currentBio = isCurrentUser ? (sessionUser?.bio ?? '') : _bio;
    final currentSchool = isCurrentUser
        ? (sessionUser?.university ?? 'Üniversite Doğrulanmadı')
        : _school;
    final currentProfileImageUrl = isCurrentUser
        ? (sessionUser?.profileImageUrl ?? '')
        : _profileImageUrl;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: isCurrentUser ? 30.h : 0.h,
        bottom: 20.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  1. PROFİL FOTO VE İSİM ALANI
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: ProfilePhoto(
                  profileImageUrl: currentProfileImageUrl,
                  badgeUrls: _badges,
                ),
              ),
              SizedBox(width: 21.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 5.h),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    currentFullName, // <-- GÜNCELLENDİ
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'SF Pro Display',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20.sp,
                                      color: onSurface,
                                      height: 1.0.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Text(
                                        currentUsername, // <-- GÜNCELLENDİ
                                        style: TextStyle(
                                          fontFamily: 'SF Pro Display',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12.sp,
                                          color: secondaryColor,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // AYARLAR BUTONU (Sadece kendi profilinde)
                        if (isCurrentUser)
                          GestureDetector(
                            onTap: () {
                              context.push('/settings');
                            },
                            child: Icon(
                              Icons.settings_outlined,
                              color: AppColors.darkBackgroundColor,
                              size: 24.sp,
                            ),
                          )
                        else
                          SizedBox(width: 24.sp),
                      ],
                    ),
                    SizedBox(height: 9.h),

                    // İSTATİSTİKLER
                    Padding(
                      padding: const EdgeInsets.only(right: 26),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ProfileStatItem(
                            count: '$numberOfEvents',
                            label: 'Buluşma',
                          ),

                          // --- TAKİPÇİ SAYISINA TIKLANDIĞINDA ---
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FollowsPage(
                                    profileUserID: widget.profileUserID,
                                    username: _username,
                                    followerCount: displayFollowerCount,
                                    followingCount: displayFollowingCount,
                                    initialTabIndex: 0,
                                  ),
                                ),
                              );
                            },
                            child: ProfileStatItem(
                              count: '$displayFollowerCount',
                              label: 'Takipçi',
                            ),
                          ),

                          // --- TAKİP (TAKİP EDİLEN) SAYISINA TIKLANDIĞINDA ---
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FollowsPage(
                                    profileUserID: widget.profileUserID,
                                    username: _username,
                                    followerCount: displayFollowerCount,
                                    followingCount: displayFollowingCount,
                                    initialTabIndex: 1,
                                  ),
                                ),
                              );
                            },
                            child: ProfileStatItem(
                              count: '$displayFollowingCount',
                              label: 'Takip',
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 13.h),

                    // BIO
                    Text(
                      currentBio,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: onSurface.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // OKUL
                    Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 16.sp,
                          color: theme.disabledColor,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            currentSchool,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: theme.disabledColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // --- 3. TAKİP ET BUTONLARI (Sadece başkasının profilinde) ---
          if (!isCurrentUser) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: LoginButton(
                    // _isFollowing yerine isCurrentlyFollowing kullanıyoruz
                    label: isCurrentlyFollowing
                        ? 'takibi bırak'
                        : (_isPrivateAccount && _hasSentFollowRequest)
                        ? 'istek gönderildi'
                        : 'takip et',
                    onPress: () {
                      if (isCurrentlyFollowing) {
                        // <-- BURASI DEĞİŞTİ
                        _showUnfollowDialog(context);
                      } else if (_isPrivateAccount) {
                        _sendFollowRequest();
                      } else {
                        _toggleFollow();
                      }
                    },
                    height: 32.h,
                    width: 361,
                    borderRadius: 20.r,
                    // _isFollowing yerine isCurrentlyFollowing kullanıyoruz
                    backgroundColor: isCurrentlyFollowing
                        ? const Color(0xFF5D6B82)
                        : ((_isPrivateAccount && _hasSentFollowRequest)
                              ? const Color(0xFFF2F2F7)
                              : primaryColor),
                    textColor:
                        (_isPrivateAccount &&
                            _hasSentFollowRequest &&
                            !isCurrentlyFollowing)
                        ? const Color(0xFF5D6B82)
                        : Colors.white,
                    borderColor: Colors.transparent,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isFollowing || !_isPrivateAccount) ...[
                  SizedBox(width: 8.w),
                  AnnouncementButton(
                    onTap: _handleAnnouncementPress,
                  ),
                ],
              ],
            ),
          ],
          if (_commonFollowers.isNotEmpty) SizedBox(height: 12.h),
          _buildFollowedBySection(context),
        ],
      ),
    );
  }

  Widget _buildFollowedBySection(BuildContext context) {
    final theme = Theme.of(context);
    final avatars = <String>[];

    var commonCount = _commonFollowers.length;
    if (commonCount == 0) {
      return const SizedBox.shrink();
    }

    if (commonCount == 1) {
      avatars.add(_commonFollowers.first.profileImageUrl);
      commonCount -= 1;
    } else if (commonCount >= 2) {
      avatars
        ..add(_commonFollowers[0].profileImageUrl)
        ..add(_commonFollowers[1].profileImageUrl);
      commonCount -= 2;
    }
    final showAdditional = commonCount > 0;

    final commonDisplayNames = _commonFollowers
        .take(2)
        .map((user) => user.username)
        .toList();

    final namesText = commonDisplayNames.join(', ');

    return Row(
      children: [
        SmallStackedAvatars(
          profileImageUrls: avatars,
          size: 24.r,
          overlap: 9.r,
          borderWidth: 0.sp,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(
                    text: namesText,
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                  if (showAdditional) ...[
                    const TextSpan(text: ' ve '),
                    TextSpan(
                      text: '$commonCount diğer kişi',
                      style: const TextStyle(fontWeight: FontWeight.w400),
                    ),
                  ],
                  const TextSpan(text: ' tarafından takip ediliyor.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingEvents) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final sessionService = getIt<SessionService>();

    return ValueListenableBuilder<SessionState>(
      valueListenable: sessionService.stateListenable,
      builder: (context, state, child) {
        // Bu sayfa benim profilim mi kontrolü
        final isCurrentUser = widget.profileUserID == state.user?.userID;

        return SafeArea(
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            // --- YENİ EKLENEN APPBAR (Sadece başkasının profilinde görünür) ---
            appBar: isCurrentUser
                ? null // Kendi profilimde AppBar yok, içerik yukarıdan başlar
                : AppBar(
                    backgroundColor: theme.colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: theme.colorScheme.onSurface,
                        size: 20.sp,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _username, // Üstte kullanıcı adını göstermek şık durur
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    centerTitle: true,
                  ),
            // ----------------------------------------------------------------
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: _buildProfileHeader(context, state),
                  ),
                  SliverPersistentHeader(
                    delegate: SectionHeaderDelegate(
                      child: ProfileTabBar(
                        currentIndex: _selectedTabIndex,
                        onTabSelected: _onTabSelected,
                      ),
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _selectedTabIndex = index);

                  getIt<AnalyticsService>().logSelectProfileSegment(
                    SelectProfileSegmentAnalyticsConfig(
                      segment: ProfileSegmentEnum.values[index],
                    ),
                  );
                },
                children: [
                  if (!_isPrivateAccount || _isFollowing) ...[
                    ProfileGridTab(
                      pinnedPosts: _pinnedPosts,
                      activePosts: _activePosts,
                      onPinChanged: _handlePinStatusChange,
                    ),
                    ProfileEventsTab(
                      currentEvents: _currentEvents,
                      consideredEvents: _consideredEvents,
                      isLoading: _isLoadingEvents,
                    ),
                    const ProfileDumpTab(),
                  ] else
                    const PrivateAccountView(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- YARDIMCI COMPONENTLER ---

class ProfileStatItem extends StatelessWidget {
  const ProfileStatItem({required this.count, required this.label, super.key});

  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          count,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  SectionHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get maxExtent => 80.h;

  @override
  double get minExtent => 80.h;

  @override
  bool shouldRebuild(SectionHeaderDelegate oldDelegate) => true;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          child,
        ],
      ),
    );
  }
}
