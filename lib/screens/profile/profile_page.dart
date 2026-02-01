import 'package:cached_network_image/cached_network_image.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/announcement_button.dart';
import 'package:outnest/components/login_button.dart';
import 'package:outnest/components/popup.dart';
import 'package:outnest/components/private_account_view.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/core/utils/types/enums/user_event_status_enum.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/friend_entity.dart';
import 'package:outnest/domain/entities/user/pinned_post_entity.dart';
import 'package:outnest/domain/entities/user/session_state.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/screens/home/post%20components/small_stacked_avatars.dart';
import 'package:outnest/screens/profile/dump_tab.dart';
import 'package:outnest/screens/profile/events_tab.dart';
import 'package:outnest/screens/profile/grid_tab.dart';
import 'package:outnest/screens/profile/profile_photo.dart';
import 'package:outnest/screens/profile/profile_tab_bar.dart';
import 'package:outnest/screens/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

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

  String _avatarUrl = '';
  final List<String> _badges = [
    'assets/badge/badge1.png',
    'assets/badge/badge2.png',
    'assets/badge/badge3.png',
  ];

  String _bio = '';
  List<EventEntity> _consideredEvents = [];
  List<EventEntity> _currentEvents = [];

  String _fullName = '';
  bool _isFollowing = false;
  bool _hasSentFollowRequest = false;
  bool _isLoadingEvents = true;
  bool _isPrivateAccount = false;
  final PageController _pageController = PageController();

  List<UserPostEntity> _pinnedPosts = [];
  List<UserPostEntity> _activePosts = [];

  String _school = '';
  int _selectedTabIndex = 0;
  String _username = '';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // --- EKLENEN/DÜZELTİLEN MANTIK: LİSTE GÜNCELLEME ---
  // Bu fonksiyon PostCard -> ProfileGridTab -> ProfilePage zinciriyle çağrılmalı
  void _handlePinStatusChange(String postId, bool isPinned) {
    setState(() {
      UserPostEntity? targetPost;

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
      final updatedPost = UserPostEntity(
        postID: targetPost.postID,
        caption: targetPost.caption,
        location: targetPost.location,
        imageUrls: targetPost.imageUrls,
        participants: targetPost.participants,
        emoteCounts: targetPost.emoteCounts,
        isPinned: isPinned, // Yeni durum
        createdAt: targetPost.createdAt,
      );

      // 3. Postu yeni listesine ekle
      if (isPinned) {
        // Pinlenenler listesinin başına ekle
        _pinnedPosts.insert(0, updatedPost);
      } else {
        // Aktifler listesine ekle ve tarihe göre yeniden sırala
        _activePosts.add(updatedPost);
        _activePosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    });
  }

  Future<void> _fetchProfileData() async {
    if (!mounted) return;

    try {
      final userRepository = getIt<UserRepository>();
      final eventRepository = getIt<EventRepository>();

      final user = await userRepository.getUser(widget.profileUserID);
      final posts = await userRepository.getUserPosts(widget.profileUserID);

      final pinnedPosts = posts.where((post) => post.isPinned).toList();
      final activePosts = posts.where((post) => !post.isPinned).toList();
      // Aktif postları tarihe göre sıralayalım
      activePosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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

      if (user!.userID == currentUser?.userID) {
        isFollowing = true;
      } else {
        isFollowing = await userRepository.isFollowing(
          currentUser!.userID,
          user.userID,
        );
      }

      bool hasSentFollowRequest = false;
      if (!isFollowing) {
        hasSentFollowRequest = await userRepository.hasSentFollowRequest(
          currentUser!.userID,
          user.userID,
        );
      }

      List<EventEntity> enrolledEvents = [];
      if (enrolledEventIds.isNotEmpty) {
        enrolledEvents = await eventRepository.getEventsByIds(enrolledEventIds);
      }

      List<EventEntity> savedEvents = [];
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

      setState(() {
        if (user != null) {
          _username = user.username;
          _fullName = user.nameSurname;
          _bio = user.bio ?? '';
          _school = user.university ?? 'Üniversite Doğrulanmadı';
          _avatarUrl = user.profileImageUrl;
        }

        _isFollowing = isFollowing;
        _isPrivateAccount = isPrivate;
        _hasSentFollowRequest = hasSentFollowRequest;

        numberOfFollowers = followerCount;
        numberOfFollowing = followeeCount;
        numberOfEvents = completedEventCount;

        _pinnedPosts = pinnedPosts;
        _activePosts = activePosts;
        _currentEvents = enrolledEvents;
        _consideredEvents = savedEvents;
        _isLoadingEvents = false;
      });
    } catch (e) {
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

    setState(() => _isFollowing = !_isFollowing);

    try {
      if (_isFollowing) {
        final me = Follower(
          userID: currentUser.userID,
          username: currentUser.username,
          profileImageUrl: currentUser.profileImageUrl,
          createdAt: DateTime.now(),
        );
        final target = Followee(
          userID: widget.profileUserID,
          username: _username,
          profileImageUrl: _avatarUrl,
          createdAt: DateTime.now(),
        );

        await Future.wait([
          userRepository.addFollowee(currentUser.userID, target),
          userRepository.addFollower(widget.profileUserID, me),
        ]);
      } else {
        await Future.wait([
          userRepository.removeFollowee(
            currentUser.userID,
            widget.profileUserID,
          ),
          userRepository.removeFollower(
            widget.profileUserID,
            currentUser.userID,
          ),
        ]);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFollowing = !_isFollowing);
      }
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
        cancelButtonText: 'vazgeç',
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
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Paylaşabileceğin aktif bir buluşman yok',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFFF6442), // Kırmızımsı Ton
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Buluşma paylaşabilmek için diğer buluşma kur ya da diğer kullanıcıların kurdukları buluşmalara katıl.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8E8E93),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. ETKİNLİK VARSA (SEÇİM POPUP) ---
  void _showShareSelectionDialog(BuildContext context, List<dynamic> events) {
    int selectedIndex = 0;

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
                padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
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
                        itemCount: events.length,
                        onPageChanged: (index) {
                          setState(() => selectedIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final event = events[index] as EventEntity;
                          final eventName =
                              (event.name ?? 'Buluşma ${index + 1}').toString();

                          // 1. URL'nin tipini kontrol et (Network mü Asset mi?)
                          final String imageUrl =
                              event.creator.profileImageUrl ??
                              FileService.defaultProfileImageUrl();
                          final bool isNetwork = imageUrl.startsWith('http');

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
                                    : AssetImage(imageUrl) as ImageProvider,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Bizimle beraber tracking\nyapmak ister misiniz???',
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
                      children: List.generate(events.length, (index) {
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
                            onPressed: () {
                              context.pop();
                              // TODO: Paylaşma işlemi (Seçilen event: events[selectedIndex])
                              debugPrint(
                                "Etkinlik paylaşıldı: ${events[selectedIndex].name}",
                              );
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

    // Aktif etkinlikleri al
    final activeEvents = currentUser.activeEvents;

    if (activeEvents == null || activeEvents.isEmpty) {
      // 0 Etkinlik -> Hata Mesajı
      _showNoShareableEventDialog(context);
    } else {
      // 1 veya Daha Fazla Etkinlik -> Seçim/Paylaşım Dialogu
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
  }

  // --- HEADER ALANI ---
  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final onSurface = theme.colorScheme.onSurface;

    final sessionUser = getIt<SessionService>().currentUser;
    final isCurrentUser = widget.profileUserID == sessionUser?.userID;

    final displayUsername = isCurrentUser ? sessionUser!.username : _username;
    final displayBio = isCurrentUser ? (sessionUser!.bio ?? '') : _bio;
    final displayAvatar = isCurrentUser
        ? sessionUser!.profileImageUrl
        : _avatarUrl;
    final displaySchool = isCurrentUser
        ? (sessionUser!.university ?? 'Üniversite Doğrulanmadı')
        : _school;
    final displayFullName = isCurrentUser
        ? sessionUser!.nameSurname
        : _fullName;

    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 30, bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 25.h),
                child: ProfilePhoto(
                  profileImageUrl: displayAvatar,
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
                            padding: EdgeInsets.only(top: 15.h),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    displayFullName,
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
                                        displayUsername,
                                        style: TextStyle(
                                          fontFamily: 'SF Pro Display',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12.sp,
                                          color: secondaryColor,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Image.asset(
                                        'assets/instagram.png',
                                        width: 20.w,
                                        height: 20.h,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.push('/settings');
                          },
                          child: Icon(
                            Icons.settings_outlined,
                            color: AppColors.darkBackgroundColor,
                            size: 24.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 9.h),
                    Padding(
                      padding: const EdgeInsets.only(right: 26),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ProfileStatItem(
                            count: '$numberOfEvents',
                            label: 'Buluşma',
                          ),
                          ProfileStatItem(
                            count: '$numberOfFollowers',
                            label: 'Takipçi',
                          ),
                          ProfileStatItem(
                            count: '$numberOfFollowing',
                            label: 'Takip',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 13.h),
                    Text(
                      displayBio,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: onSurface.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 12.h),
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
                            displaySchool,
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
          if (!isCurrentUser) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: LoginButton(
                    label: _isFollowing
                        ? 'takip ediyorsun'
                        : (_isPrivateAccount && _hasSentFollowRequest)
                        ? 'istek gönderildi'
                        : 'takip et',
                    onPress: () {
                      if (_isFollowing) {
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
                    borderWidth: 0,
                    backgroundColor: _isFollowing
                        ? const Color(0xFF5D6B82)
                        : ((_isPrivateAccount && _hasSentFollowRequest)
                              ? const Color(
                                  0xFFF2F2F7,
                                )
                              : primaryColor),
                    textColor:
                        (_isPrivateAccount &&
                            _hasSentFollowRequest &&
                            !_isFollowing)
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
                    onTap: _handleAnnouncementPress, // Fonksiyon bağlandı
                  ),
                ],
              ],
            ),
          ],
          SizedBox(height: 12.h),
          _buildFollowedBySection(context),
        ],
      ),
    );
  }

  Widget _buildFollowedBySection(BuildContext context) {
    final theme = Theme.of(context);
    final avatars = [
      FileService.defaultProfileImageUrl(),
      FileService.defaultProfileImageUrl(),
    ];

    return Row(
      children: [
        SmallStackedAvatars(
          avatarUrls: avatars,
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
                children: const [
                  TextSpan(
                    text: 'durucetin, yarkinyoruk',
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                  TextSpan(text: ' ve '),
                  TextSpan(
                    text: '4 diğer kişi',
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                  TextSpan(text: ' tarafından takip ediliyor.'),
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

    return ValueListenableBuilder<SessionState?>(
      valueListenable: sessionService.stateListenable,
      builder: (context, state, child) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: _buildProfileHeader(context),
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
                },
                children: [
                  if (!_isPrivateAccount || _isFollowing) ...[
                    // --- DÜZELTME: ProfileGridTab'e callback ekliyoruz ---
                    // Lütfen ProfileGridTab widget'ınızı bu callback'i (onPinChanged)
                    // kabul edecek şekilde güncelleyin.
                    ProfileGridTab(
                      pinnedPosts: _pinnedPosts,
                      activePosts: _activePosts,
                      onPinChanged: _handlePinStatusChange, // <-- BÖYLE EKLEYİN
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
