import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/utils/types/enums/profile_segment_enum.dart';
import 'package:outnest/core/utils/types/enums/user_event_status_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/entities/user/friend_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/analytics/event_configs/select_profile_segment_analytics_config.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/session_state.dart';
import 'package:outnest/presentation/home/view/components/post/small_stacked_avatars.dart';
import 'package:outnest/presentation/profile/view/community_info_page.dart';
import 'package:outnest/presentation/profile/view/components/dump_tab.dart';
import 'package:outnest/presentation/profile/view/components/events_tab.dart';
import 'package:outnest/presentation/profile/view/components/grid_tab.dart';
import 'package:outnest/presentation/profile/view/components/profile_tab_bar.dart';
import 'package:outnest/presentation/settings/view/components/add_authority.dart';
import 'package:outnest/presentation/shared/login_button.dart';
import 'package:outnest/presentation/shared/popup.dart';

class CommunityProfilePage extends StatefulWidget {
  const CommunityProfilePage({super.key, required this.profileUserID});
  final String profileUserID;

  @override
  State<CommunityProfilePage> createState() => _CommunityProfilePageState();
}

class _CommunityProfilePageState extends State<CommunityProfilePage> {
  final _sessionService = getIt<SessionService>();

  bool _isLoading = true;
  int _selectedTabIndex = 0;
  final PageController _pageController = PageController();

  CompactUserEntity? _communityUser;
  int _numberOfEvents = 0;
  int _numberOfFollowers = 0;

  bool? _optimisticIsMember;
  int _followerCountModifier = 0;
  bool _isTogglingMembership = false;

  StreamSubscription<List<PostEntity>>? _postsSubscription;

  // Listeler
  List<PostEntity> _pinnedPosts = [];
  List<PostEntity> _activePosts = [];
  List<EventEntity> _currentEvents = [];
  final List<EventEntity> _consideredEvents = [];
  final List<CompactUserEntity> _commonMembers = [];

  final List<String> _badges = [
    'assets/badge/badge1.png',
    'assets/badge/badge2.png',
    'assets/badge/badge3.png',
  ];

  @override
  void initState() {
    super.initState();
    _initPostStream();
    _fetchCommunityData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _postsSubscription?.cancel();
    super.dispose();
  }

  void _initPostStream() {
    final userRepository = getIt<UserRepository>();

    _postsSubscription = userRepository
        .getUserPostsStream(widget.profileUserID)
        .listen(
          (allPosts) {
            if (!mounted) return;
            final pinned = allPosts.where((p) => p.isPinned).toList();
            final active = allPosts.where((p) => !p.isPinned).toList()
              ..sort((a, b) => b.createdAt!.compareTo(a.createdAt));

            setState(() {
              _pinnedPosts = pinned;
              _activePosts = active;
            });
          },
          onError: (error) {
            if (mounted) debugPrint('Post Stream Hatası: $error');
          },
        );
  }

  void _handlePinStatusChange(String postId, bool isPinned) {
    setState(() {
      PostEntity? targetPost;
      final pinnedIndex = _pinnedPosts.indexWhere((p) => p.postID == postId);
      if (pinnedIndex != -1) {
        targetPost = _pinnedPosts.removeAt(pinnedIndex);
      } else {
        final activeIndex = _activePosts.indexWhere((p) => p.postID == postId);
        if (activeIndex != -1) {
          targetPost = _activePosts.removeAt(activeIndex);
        }
      }

      if (targetPost == null) return;

      final updatedPost = PostEntity(
        postID: targetPost.postID,
        caption: targetPost.caption,
        location: targetPost.location,
        imageUrls: targetPost.imageUrls,
        participants: targetPost.participants,
        emoteCounts: targetPost.emoteCounts,
        isPinned: isPinned,
        createdAt: targetPost.createdAt,
        creator: targetPost.creator,
        eventID: targetPost.eventID,
        hobbies: targetPost.hobbies,
        showParticipants: targetPost.showParticipants,
        includeInDump: targetPost.includeInDump,
        updatedAt: targetPost.updatedAt,
      );

      if (isPinned) {
        _pinnedPosts.insert(0, updatedPost);
      } else {
        _activePosts
          ..add(updatedPost)
          ..sort((a, b) => b.createdAt!.compareTo(a.createdAt));
      }
    });
  }

  Future<void> _fetchCommunityData() async {
    if (!mounted) return;

    try {
      final userRepository = getIt<UserRepository>();
      final eventRepository = getIt<EventRepository>();

      // 1. Temel Kullanıcı Verisini
      final user = await userRepository.getUserPublicData(widget.profileUserID);

      // 2. Sadece Etkinlik Sayısı
      final userEventsEnrolled = await userRepository.getUserEventLog(
        widget.profileUserID,
      );
      int completedEventCount = 0;
      final enrolledEventIds = <String>[];

      for (final event in userEventsEnrolled) {
        switch (event.status) {
          case UserEventStatusEnum.upcoming:
          case UserEventStatusEnum.ongoing:
            enrolledEventIds.add(event.eventId);
            break;
          case UserEventStatusEnum.completed:
            completedEventCount += 1;
            break;
          default:
            break;
        }
      }

      var enrolledEvents = <EventEntity>[];
      if (enrolledEventIds.isNotEmpty) {
        enrolledEvents = await eventRepository.getEventsByIds(enrolledEventIds);
      }

      //TODO: Optimize
      final numberOfFollowers = await userRepository.getFollowersCount(
        user!.userID,
      );
      if (!mounted) return;

      setState(() {
        _communityUser = user;
        _numberOfEvents = completedEventCount;
        _numberOfFollowers = numberOfFollowers;
        _currentEvents = enrolledEvents;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Topluluk verisi çekilirken hata: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- KATIL/ÇIK MANTIĞI ---
  // --- KATIL/ÇIK MANTIĞI ---
  Future<void> _toggleJoinCommunity(bool isCurrentlyMember) async {
    if (_isTogglingMembership) return; // Çoklu tıklama spam'ini engelle

    final userRepository = getIt<UserRepository>();
    final sessionService = getIt<SessionService>();
    final currentUser = sessionService.currentUser;
    if (currentUser == null) return;

    // 1. OPTIMISTIC UPDATE: Sunucuyu beklemeden arayüzü anında güncelle
    final newMemberStatus = !isCurrentlyMember;
    setState(() {
      _isTogglingMembership = true; // Butonu kilitle (Spam engeli)
      _optimisticIsMember = newMemberStatus; // Anında 'Katıldın' yazdır
      _followerCountModifier = newMemberStatus ? 1 : -1;
    });
    try {
      if (newMemberStatus) {
        // KATIL
        final me = Follower(
          userID: currentUser.userID,
          username: currentUser.username,
          profileImageUrl: currentUser.profileImageUrl,
          createdAt: DateTime.now(),
        );
        final target = Followee(
          userID: widget.profileUserID,
          username: _communityUser?.username ?? '',
          profileImageUrl: _communityUser?.profileImageUrl ?? '',
          createdAt: DateTime.now(),
        );

        await userRepository.addFollowee(currentUser.userID, target);
        await userRepository.addFollower(widget.profileUserID, me);
      } else {
        // ÇIK
        await userRepository.removeFollowee(
          currentUser.userID,
          widget.profileUserID,
        );
        await userRepository.removeFollower(
          widget.profileUserID,
          currentUser.userID,
        );
      }

      await sessionService.refreshSession();

      // 2. BAŞARILI: Geçici optimistik state'i kalıcılaştır ve temizle
      if (mounted) {
        setState(() {
          _numberOfFollowers +=
              _followerCountModifier; // Gerçek takipçi sayısını güncelle
          _optimisticIsMember =
              null; // null yaparak SessionState'deki asıl değere dönüş yapıyoruz
          _followerCountModifier = 0;
          _isTogglingMembership = false;
        });
      }
    } catch (e) {
      debugPrint("İşlem başarısız: $e");
      if (mounted) {
        // 3. ROLLBACK (GERİ ALMA): Hata durumunda arayüzü eski haline döndür
        setState(() {
          _optimisticIsMember = null;
          _followerCountModifier = 0;
          _isTogglingMembership = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşlem başarısız oldu, lütfen tekrar deneyin.'),
          ),
        );
      }
    }
  }

  void _showUnfollowDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Popup(
        title:
            '${_communityUser?.username ?? ''} topluluğundan ayrılmak istediğine emin misin?',
        description: 'Tekrar katılmak için istek göndermen gerekebilir.',
        confirmButtonText: 'ayrıl',
        confirmButtonColor: const Color(0xFF5D6B82),
        onConfirm: () {
          context.pop();
          _toggleJoinCommunity(true);
        },
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final sessionService = getIt<SessionService>();

    final isCurrentUser =
        widget.profileUserID == sessionService.currentUser?.userID;

    final username = _communityUser?.username ?? '';

    return ValueListenableBuilder<SessionState>(
      valueListenable: sessionService.stateListenable,
      builder: (context, state, child) {
        final actualIsMember = state.followees.any(
          (f) => f.userID == widget.profileUserID,
        );

        // Arayüze basılacak durum: Optimistic bir işlem varsa onu, yoksa gerçek durumu al
        final isMember = _optimisticIsMember ?? actualIsMember;

        return SafeArea(
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,

            appBar: isCurrentUser
                ? null
                : AppBar(
                    backgroundColor: theme.colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    titleSpacing: 0,
                    centerTitle: false,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: theme.colorScheme.onSurface,
                        size: 20.sp,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    title: Text(
                      username,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),

            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: _buildCommunityHeader(
                      context,
                      isCurrentUser,
                      isMember,
                    ),
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
                onPageChanged: (index) =>
                    setState(() => _selectedTabIndex = index),
                children: [
                  ProfileGridTab(
                    pinnedPosts: _pinnedPosts,
                    activePosts: _activePosts,
                    onPinChanged: _handlePinStatusChange,
                  ),
                  ProfileEventsTab(
                    currentEvents: _currentEvents,
                    consideredEvents: _consideredEvents,
                    isLoading: _isLoading,
                  ),
                  const ProfileDumpTab(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommunityHeader(
    BuildContext context,
    bool isCurrentUser,
    bool isMember,
  ) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final profileImageUrl = _communityUser?.profileImageUrl ?? '';
    final nameSurname = _communityUser?.nameSurname ?? '';
    final username = _communityUser?.username ?? '';
    final bio = _communityUser?.bio ?? '';
    final school = _communityUser?.university ?? 'Üniversite Doğrulanmadı';
    final displayTitle = nameSurname.isNotEmpty ? nameSurname : username;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: isCurrentUser ? 24.h : 8.h,
        bottom: 20.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 38.r,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: profileImageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(profileImageUrl)
                        : null,
                    child: profileImageUrl.isEmpty
                        ? Icon(Icons.groups, size: 30.sp, color: Colors.grey)
                        : null,
                  ),
                  SizedBox(height: 8.h),
                  if (_badges.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _badges.map((badge) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2.w),
                          child: Image.asset(badge, width: 22.r, height: 22.r),
                        );
                      }).toList(),
                    ),
                ],
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  displayTitle,
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.sp,
                                    color: onSurface,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Icon(
                                  Icons.group_rounded,
                                  size: 22.sp,
                                  color: onSurface.withOpacity(0.9),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: () => context.push('/settings'),
                            child: Icon(
                              Icons.settings_outlined,
                              color: onSurface,
                              size: 26.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem('$_numberOfEvents', ' Etkinlik'),
                        _buildStatItem(
                          '${_numberOfFollowers + _followerCountModifier}',
                          ' Üye',
                        ),
                        _buildStatItem('0', ' Etkileşim'),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      bio,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        color: onSurface.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: 8.h),
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
                            school,
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

          SizedBox(height: 20.h),

          // Test için katıl ve iletişim butonları ekledim
          Row(
            children: [
              Expanded(
                flex: 5,
                child: LoginButton(
                  label: isMember ? 'katıldın' : 'katıl',
                  onPress: _isTogglingMembership
                      ? () {}
                      : () {
                          if (isMember) {
                            _showUnfollowDialog(context);
                          } else {
                            _toggleJoinCommunity(false);
                          }
                        },
                  height: 32.h,
                  width: double.infinity,
                  borderRadius: 20.r,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  backgroundColor: isMember
                      ? const Color(0xFFF2F2F7)
                      : const Color(0xFFFF6B4A),
                  textColor: isMember ? const Color(0xFF5D6B82) : Colors.white,
                  borderColor: Colors.transparent,
                ),
              ),
              SizedBox(width: 10.w),

              Expanded(
                flex: 5,
                child: LoginButton(
                  label: 'iletişim',
                  onPress: () {
                    showModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => const CommunityContactBottomSheet(
                        instagram: 'instagram.com/itugastronomi/',
                        website: 'https://chat.whatsapp.com/abc...',
                        email: 'gastronomi@itu.edu.tr',
                      ),
                    );
                  },
                  height: 32.h,
                  width: double.infinity,
                  borderRadius: 20.r,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  backgroundColor: const Color(0xFFF2F2F7),
                  textColor: const Color(0xFF5D6B82),
                  borderColor: Colors.transparent,
                ),
              ),
              SizedBox(width: 10.w),

              Container(
                width: 32.h,
                height: 32.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF5D6B82).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.info_outline_rounded,
                    color: const Color(0xFF5D6B82),
                    size: 20.sp,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommunityInfoPage(
                          communityData: _communityUser!.communityData,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          if (_commonMembers.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _buildCommonMembersText(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    const statColor = Color(0xFF19446B);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: count,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: statColor,
            ),
          ),
          TextSpan(
            text: label,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: statColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonMembersText(ThemeData theme) {
    return Row(
      children: [
        SmallStackedAvatars(
          profileImageUrls: _commonMembers
              .take(2)
              .map((e) => e.profileImageUrl)
              .toList(),
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
                  fontSize: 11.sp,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(
                    text: _commonMembers.first.username,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' ve '),
                  TextSpan(
                    text: '${_commonMembers.length - 1} diğer kişi',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' bu topluluğa katıldı.'),
                ],
              ),
            ),
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
    return Container(
      color: Theme.of(context).colorScheme.surface,
      alignment: Alignment.center,
      child: Stack(alignment: Alignment.bottomCenter, children: [child]),
    );
  }
}

class CommunityContactBottomSheet extends StatelessWidget {
  const CommunityContactBottomSheet({
    required this.instagram,
    required this.website,
    required this.email,
    super.key,
  });
  final String instagram;
  final String website;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 12.h,
        bottom: MediaQuery.of(context).padding.bottom + 24.h,
        left: 24.w,
        right: 24.w,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 24.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Instagram
          if (instagram.isNotEmpty)
            _ContactItem(
              icon: Icons.camera_alt_outlined,
              text: instagram,
              onTap: () {},
            ),
          if (instagram.isNotEmpty) SizedBox(height: 8.h),

          // Website / WhatsApp
          if (website.isNotEmpty)
            _ContactItem(
              icon: Icons.link_rounded,
              text: website,
              onTap: () {},
            ),
          if (website.isNotEmpty) SizedBox(height: 8.h),

          // Email
          if (email.isNotEmpty)
            _ContactItem(
              icon: Icons.mail_outline_rounded,
              text: email,
              onTap: () {},
            ),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ContactItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF19446B), size: 22.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 15.sp,
                  color: const Color(0xFF19446B),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
