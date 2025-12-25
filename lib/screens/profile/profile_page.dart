import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/login_button.dart';
import 'package:bulusalim/core/utils/types/enums/event_status_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.profileUserID, super.key});

  final String profileUserID;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- DURUM YÖNETİMİ ---
  int _selectedTabIndex = 0;
  final PageController _pageController = PageController();

  // --- VERİLER ---
  List<EventEntity> _currentEvents = [];
  List<EventEntity> _consideredEvents = [];
  List<PinnedPostEntity> _pinnedPosts = [];

  bool _isLoadingEvents = true;

  // --- MOCK PROFİL BİLGİLERİ ---
  String _username = '';
  String _fullName = '';
  String _bio = '';
  String _school = '';
  String _avatarUrl = '';
  final List<String> _badges = [];
  int numberOfFollowers = 0;
  int numberOfFollowing = 0;
  int numberOfEvents = 0;

  final bool _isPrivateAccount = false;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    if (!mounted) return;

    final userRepository = getIt<UserRepository>();
    final eventRepository = getIt<EventRepository>();
    final user = await userRepository.getUser(widget.profileUserID);
    final pinnedPosts = await userRepository.getPinnedPosts(
      widget.profileUserID,
    );

    final userEventsEnrolled = await userRepository.getUserEventHistory(
      widget.profileUserID,
    );
    final enrolledEventIds = <Identifier>[];
    final savedEventIds = <Identifier>[];

    for (final event in userEventsEnrolled) {
      switch (event.status) {
        case EventStatusEnum.upcoming:
        case EventStatusEnum.ongoing:
          enrolledEventIds.add(event.eventId);
        case EventStatusEnum.saved:
          savedEventIds.add(event.eventId);
        case EventStatusEnum.completed:
          numberOfEvents += 1;
        case EventStatusEnum.cancelled:
          break;
        case EventStatusEnum.pending:
          break;
        case EventStatusEnum.declined:
          break;
      }
    }

    List<EventEntity> enrolledEvents;
    if (enrolledEventIds.isNotEmpty) {
      enrolledEvents = await eventRepository.getEventsByIds(
        enrolledEventIds,
      );
    } else {
      enrolledEvents = [];
    }

    List<EventEntity> savedEvents;
    if (savedEventIds.isNotEmpty) {
      savedEvents = await eventRepository.getEventsByIds(
        savedEventIds,
      );
    } else {
      savedEvents = [];
    }

    if (!mounted) return;

    setState(() {
      if (user != null) {
        _username = user.username;
        _fullName = user.username;
        _bio = user.bio ?? '';
        _school = user.organization;
        _avatarUrl = user.profileImageUrl;
      }

      _pinnedPosts = pinnedPosts;
      _currentEvents = enrolledEvents;
      _consideredEvents = savedEvents;
      _isLoadingEvents = false;
    });
  }

  void _toggleFollow() {
    setState(() => _isFollowing = !_isFollowing);
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTabIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              ProfileGridTab(pinnedPosts: _pinnedPosts),

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
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        size: 16.sp,
                                        color: onSurface.withOpacity(0.6),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Icon(
                          Icons.category_outlined,
                          color: secondaryColor,
                          size: 24.sp,
                        ),
                      ],
                    ),
                    SizedBox(height: 9.h),
                    Padding(
                      padding: const EdgeInsets.only(right: 26),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const ProfileStatItem(count: '47', label: 'Etkinlik'),
                          ProfileStatItem(
                            count: _isFollowing ? '139' : '138',
                            label: 'Takipçi',
                          ),
                          const ProfileStatItem(count: '125', label: 'Takip'),
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
                        : (_isPrivateAccount ? 'istek gönder' : 'takip et'),
                    onPress: _toggleFollow,
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
  double get minExtent => 80.h;

  @override
  double get maxExtent => 80.h;

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

  @override
  bool shouldRebuild(SectionHeaderDelegate oldDelegate) => true;
}
