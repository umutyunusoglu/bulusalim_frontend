import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/login_button.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/core/utils/types/enums/user_event_status_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/user/friend_entity.dart';
import 'package:bulusalim/domain/entities/user/pinned_post_entity.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/domain/repositories/user_repository.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:bulusalim/screens/home/post%20components/small_stacked_avatars.dart';
import 'package:bulusalim/screens/profile/dump_tab.dart';
import 'package:bulusalim/screens/profile/events_tab.dart';
import 'package:bulusalim/screens/profile/grid_tab.dart';
import 'package:bulusalim/screens/profile/profile_photo.dart';
import 'package:bulusalim/screens/profile/profile_tab_bar.dart';
import 'package:bulusalim/screens/settings/settings.dart';
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
  // --- VERİLER ---
  List<EventEntity> _currentEvents = [];

  String _fullName = '';
  bool _isFollowing = false;
  bool _hasSentFollowRequest = false;
  bool _isLoadingEvents = true;
  final bool _isPrivateAccount = false;
  final PageController _pageController = PageController();

  List<UserPostEntity> _pinnedPosts = [];
  List<UserPostEntity> _activePosts = [];

  String _school = '';
  // --- DURUM YÖNETİMİ ---
  int _selectedTabIndex = 0;

  // --- MOCK PROFİL BİLGİLERİ ---
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

  Future<void> _fetchProfileData() async {
    if (!mounted) return;

    debugPrint("--- FETCH BAŞLADI: ${widget.profileUserID} ---");

    try {
      // 1. ADIM: Servisleri çağırma
      debugPrint("1. GetIt servisleri alınıyor...");
      final userRepository = getIt<UserRepository>();
      final eventRepository = getIt<EventRepository>();
      debugPrint("1. Servisler başarıyla alındı.");

      // 2. ADIM: User verisini çekme
      debugPrint("2. getUser çağrılıyor...");
      final user = await userRepository.getUser(widget.profileUserID);
      debugPrint(
        "2. User verisi geldi: ${user?.username ?? 'USER NULL GELDİ'}",
      );

      // 3. ADIM: Pinned Postları çekme
      debugPrint("3. Pinned posts çekiliyor...");
      final posts = await userRepository.getUserPosts(
        widget.profileUserID,
      );

      final pinnedPosts = posts.where((post) => post.isPinned).toList();
      final activePosts = posts.where((post) => !post.isPinned).toList();

      // 4. ADIM: Event Loglarını çekme
      debugPrint("4. Event logları çekiliyor...");
      final userEventsEnrolled = await userRepository.getUserEventLog(
        widget.profileUserID,
      );

      // --- BURADAN SONRASI SENİN MEVCUT MANTIK KODLARIN ---
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

      //TODO: Inefficient way to get follower/followee counts
      final followerCount = await userRepository.getFollowersCount(
        widget.profileUserID,
      );
      final followeeCount = await userRepository.getFolloweesCount(
        widget.profileUserID,
      );

      final completedEventCount = await userRepository.getCompletedEventCount(
        widget.profileUserID,
      );

      if (!mounted) return;

      setState(() {
        if (user != null) {
          _username = user.username;
          _fullName = user.username;
          _bio = user.bio ?? '';
          _school = user.university ?? 'Üniversite Doğrulanmadı';
          // URL boş gelse bile boş string atıyoruz, null hatası almamak için
          _avatarUrl = user.profileImageUrl;
        }

        _isFollowing = isFollowing;
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
    } catch (e, stackTrace) {
      // HATA BURAYA DÜŞECEK

      // Kullanıcı sonsuza kadar loading'de kalmasın diye:
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
    //TODO: Popups ?
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

    final isCurrentUser =
        widget.profileUserID == getIt<SessionService>().currentUser?.userID;

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
                  profileImageUrl: _avatarUrl,
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
                                    _fullName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Urbanist',
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
                                        _username,
                                        style: TextStyle(
                                          fontFamily: 'Urbanist',
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
                      _bio,
                      style: TextStyle(
                        fontFamily: 'Urbanist',
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
                            _school,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Urbanist',
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
                    onPress: _isFollowing
                        ? _toggleFollow
                        : (_isPrivateAccount
                              ? _sendFollowRequest
                              : _toggleFollow),
                    height: 32.h,
                    width: 361,
                    borderRadius: 20.r,
                    borderWidth: 1.5,
                    backgroundColor: _isFollowing
                        ? theme.colorScheme.surface
                        : primaryColor,
                    textColor: _isFollowing
                        ? primaryColor
                        : theme.colorScheme.surface,
                    borderColor: primaryColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isFollowing) ...[
                  SizedBox(width: 16.w),
                  Container(
                    height: 32.h,
                    width: 78.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: IconButton(
                      icon: Center(
                        child: Icon(
                          Icons.campaign_outlined,
                          color: onSurface,
                          size: 18.sp,
                        ),
                      ),
                      onPressed: () {},
                    ),
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
      'https://picsum.photos/seed/1/100/100',
      'https://picsum.photos/seed/2/100/100',
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
                  fontFamily: 'Urbanist',
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
        body: Center(
          child: CircularProgressIndicator(), // Dönen yükleme çubuğu
        ),
      );
    }

    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 1. HEADER
              SliverToBoxAdapter(child: _buildProfileHeader(context)),

              // 2. TAB BAR (Sticky)
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
          // 3. İÇERİK (Modüler Yapı)
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _selectedTabIndex = index);
            },
            children: [
              // TAB 1: Grid (Fotoğraflar)
              ProfileGridTab(
                pinnedPosts: _pinnedPosts,
                activePosts: _activePosts,
              ),

              // TAB 2: Events (Etkinlikler)
              ProfileEventsTab(
                currentEvents: _currentEvents,
                consideredEvents: _consideredEvents,
                isLoading: _isLoadingEvents,
              ),

              // TAB 3: Dump (Kilitli)
              const ProfileDumpTab(),
            ],
          ),
        ),
      ),
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
            fontFamily: 'Urbanist',
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Urbanist',
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
          // Çizgi kaldırıldı (İsteğine göre)
          child,
        ],
      ),
    );
  }
}
