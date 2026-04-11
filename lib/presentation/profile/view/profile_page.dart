// This file intentionally uses both UserEntity and UserCompactEntity (sometimes via dynamic calls) for convenience when sharing the same variable.
// ignore_for_file: avoid_dynamic_calls
import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_event_providers.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_friend_providers.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/application/profile/profile_notifier.dart';
import 'package:outnest/application/profile/profile_providers.dart';
import 'package:outnest/core/utils/types/enums/profile_segment_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/analytics/event_configs/select_profile_segment_analytics_config.dart';
import 'package:outnest/presentation/profile/view/components/dump_tab.dart';
import 'package:outnest/presentation/profile/view/components/events_tab.dart';
import 'package:outnest/presentation/profile/view/components/followed_by_section.dart';
import 'package:outnest/presentation/profile/view/components/grid_tab.dart';
import 'package:outnest/presentation/profile/view/components/private_account_view.dart';
import 'package:outnest/presentation/profile/view/components/profile_bio_section.dart';
import 'package:outnest/presentation/profile/view/components/profile_follow_button.dart';
import 'package:outnest/presentation/profile/view/components/profile_header.dart';
import 'package:outnest/presentation/profile/view/components/profile_photo.dart';
import 'package:outnest/presentation/profile/view/components/profile_section_header_delegate.dart';
import 'package:outnest/presentation/profile/view/components/profile_share_bottom_sheet.dart';
import 'package:outnest/presentation/profile/view/components/profile_stats_row.dart';
import 'package:outnest/presentation/profile/view/components/profile_tab_bar.dart';
import 'package:outnest/presentation/profile/view/dialogs/show_no_shareable_event_dialog.dart';
import 'package:outnest/presentation/profile/view/dialogs/show_share_selection_dialog.dart';
import 'package:outnest/presentation/profile/view/dialogs/show_unfollow_dialog.dart';
import 'package:share_plus/share_plus.dart';

class ProfilePage extends HookConsumerWidget {
  const ProfilePage({required this.profileUserID, super.key});

  final String profileUserID;

  static const _badges = [
    'assets/badge/badge1.png',
    'assets/badge/badge2.png',
    'assets/badge/badge3.png',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final selectedTabIndex = useState(0);

    // ─── Current user (Riverpod, SessionService yok) ─────────
    final myUserId = ref.watch(currentUserIDProvider);
    final currentUser = ref.watch(currentUserEntityProvider).value;
    final isCurrentUser = profileUserID == myUserId;

    // ─── Profile data providers ──────────────────────────────
    final profileUserAsync = ref.watch(profileUserProvider(profileUserID));
    final postsAsync = ref.watch(profilePostsProvider(profileUserID));
    final followStatusAsync = ref.watch(
      profileFollowStatusProvider(profileUserID),
    );
    final statsAsync = ref.watch(profileStatsProvider(profileUserID));
    final eventsAsync = ref.watch(profileEventsProvider(profileUserID));
    final commonFollowers =
        ref.watch(profileCommonFollowersProvider(profileUserID)).value ?? [];

    // ─── Session-based providers ─────────────────────────────
    final myFollowees = ref.watch(currentUserFolloweesProvider).value ?? [];
    final myFollowerCount = ref.watch(currentUserFollowerCountProvider);
    final myFolloweeCount = ref.watch(currentUserFolloweeCountProvider);
    final activeEvents = ref.watch(upcomingAndOngoingEventsProvider);

    // ─── Action notifier ─────────────────────────────────────
    final actionState = ref.watch(profileActionProvider(profileUserID));
    final actionNotifier = ref.read(
      profileActionProvider(profileUserID).notifier,
    );

    // ─── Loading ─────────────────────────────────────────────
    if (profileUserAsync.isLoading || profileUserAsync.value == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = profileUserAsync.value;

    // ─── Derived fields ──────────────────────────────────────
    final username = isCurrentUser
        ? (currentUser?.username ?? '')
        : '${user.username ?? ''}';
    final fullName = isCurrentUser
        ? (currentUser?.nameSurname ?? '')
        : '${user.nameSurname ?? ''}';
    var bio = isCurrentUser ? currentUser?.bio ?? '' : '${user.bio ?? ''}';
    if (bio.trim().isEmpty) bio = 'Merhaba, profilime hoşgeldiniz.';
    final school = isCurrentUser
        ? (currentUser?.university ?? 'Üniversite Doğrulanmadı')
        : '${user.university ?? 'Üniversite Doğrulanmadı'}';
    final profileImageUrl = isCurrentUser
        ? (currentUser?.profileImageUrl ?? '')
        : '${user.profileImageUrl ?? ''}';
    final isPrivateAccount = (user.isPrivate as bool?) == true;

    // ─── Follow status ───────────────────────────────────────
    final followStatus = followStatusAsync.value;
    final isFollowing = followStatus?.isFollowing ?? false;
    final hasSentFollowRequest =
        actionState.hasSentFollowRequest ||
        (followStatus?.hasSentFollowRequest ?? false);
    final isCurrentlyFollowing =
        isCurrentUser || myFollowees.any((f) => f.userID == profileUserID);

    // ─── Stats ───────────────────────────────────────────────
    final stats = statsAsync.value;
    final numberOfEvents = stats?.events ?? 0;
    var displayFollowerCount = isCurrentUser
        ? myFollowerCount
        : (stats?.followers ?? 0);
    final displayFollowingCount = isCurrentUser
        ? myFolloweeCount
        : (stats?.following ?? 0);
    if (!isCurrentUser) {
      if (isFollowing && !isCurrentlyFollowing) {
        displayFollowerCount = (displayFollowerCount - 1).clamp(
          0,
          displayFollowerCount,
        );
      } else if (!isFollowing && isCurrentlyFollowing) {
        displayFollowerCount = displayFollowerCount + 1;
      }
    }

    // ─── Posts ───────────────────────────────────────────────
    final posts = postsAsync.value;
    final pinnedPosts = posts?.pinned ?? <PostEntity>[];
    final activePosts = posts?.active ?? <PostEntity>[];

    // ─── Events ──────────────────────────────────────────────
    final events = eventsAsync.value;
    final currentEvents = events?.current ?? <EventEntity>[];
    final consideredEvents = events?.considered ?? <EventEntity>[];
    final isLoadingEvents = eventsAsync.isLoading;

    // ─── Tab handler ─────────────────────────────────────────
    Future<void> onTabSelected(int index) async {
      selectedTabIndex.value = index;
      await pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      unawaited(
        getIt<AnalyticsService>().logSelectProfileSegment(
          SelectProfileSegmentAnalyticsConfig(
            segment: ProfileSegmentEnum.values[index],
          ),
        ),
      );
    }

    Future<void> handleAnnouncementPress() async {
      if (activeEvents.isEmpty) {
        showNoShareableEventDialog(context);
      } else {
        await showShareSelectionDialog(
          context,
          shareEvents: activeEvents,
          profileUserID: profileUserID,
          username: username,
          profileImageUrl: profileImageUrl,
        );
      }
    }

    Future<void> showFullScreenImage(
      BuildContext context,
      String imageUrl,
    ) async {
      // Url boş değilse ve geçerli bir web adresi (http) içeriyorsa true döner
      final bool hasValidImage =
          imageUrl.trim().isNotEmpty && imageUrl.startsWith('http');

      await showGeneralDialog(
        context: context,
        barrierDismissible: true, // Arka plana tıklayınca kapansın
        barrierLabel: 'Close',
        barrierColor: Colors.black.withOpacity(0.5), // Arka plan karartma
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(), // Kapatmak için dokun
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // Full Screen Blur
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(color: Colors.black26),
                    ),
                  ),
                  // Ortalanmış Resim
                  Center(
                    child: Hero(
                      tag: 'profile_pic',
                      child: Container(
                        width: 264.w,
                        height: 264.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: hasValidImage
                              // 1. DURUM: Kullanıcının resim linki var
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.black, // Siyah zemin
                                  ),
                                  // Link kırık çıkar veya yükleme başarısız olursa default asset
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                        'assets/defaults/default_profile.jpg',
                                        fit: BoxFit.cover,
                                      ),
                                )
                              // 2. DURUM: Kullanıcının hiç resmi yok (veya link değil)
                              : Image.asset(
                                  'assets/defaults/default_profile.jpg',
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    void openCustomShareMenu() {
      final shareUrl = 'https://outnest.app/share/profile/$profileUserID';

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ProfileShareBottomSheet(
          username: username,
          profileImageUrl: profileImageUrl,
          profileUrl: shareUrl,
          onSharePressed: () async {
            await SharePlus.instance.share(
              ShareParams(text: shareUrl),
            );
          },
        ),
      );
    }

    // ─── BUILD ───────────────────────────────────────────────
    final theme = Theme.of(context);

    return Stack(
      children: [
        SafeArea(
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: isCurrentUser
                ? null
                : AppBar(
                    backgroundColor: theme.colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(
                        Symbols.reply,
                        weight: 400,
                        color: theme.colorScheme.onSurface,
                        size: 20.sp,
                      ),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                    ),
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
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
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 16.w,
                        right: 16.w,
                        top: isCurrentUser ? 30.h : 0.h,
                        bottom: 20.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PROFİL FOTO VE İSİM
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 12.h),
                                child: GestureDetector(
                                  onTap: () => showFullScreenImage(
                                    context,
                                    profileImageUrl,
                                  ),
                                  child: ProfilePhoto(
                                    profileImageUrl: profileImageUrl,
                                    badgeUrls: _badges,
                                  ),
                                ),
                              ),
                              SizedBox(width: 21.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ProfileHeader(
                                      fullName: fullName,
                                      username: username,

                                      isCurrentUser: isCurrentUser,
                                      onShareTap: openCustomShareMenu,
                                    ),
                                    SizedBox(height: 9.h),
                                    // İSTATİSTİKLER
                                    ProfileStatsRow(
                                      profileUserID: profileUserID,
                                      username: username,
                                      numberOfEvents: numberOfEvents,
                                      followerCount: displayFollowerCount,
                                      followingCount: displayFollowingCount,
                                    ),
                                    SizedBox(height: 13.h),
                                    // BIO
                                    ProfileBioSection(
                                      bio: bio,
                                      school: school,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // TAKİP ET BUTONLARI
                          if (!isCurrentUser) ...[
                            SizedBox(height: 12.h),
                            ProfileFollowButton(
                              isCurrentlyFollowing: isCurrentlyFollowing,
                              isPrivateAccount: isPrivateAccount,
                              hasSentFollowRequest: hasSentFollowRequest,
                              isFollowing: isFollowing,
                              onFollowTap: () => actionNotifier.toggleFollow(
                                context,
                                username: username,
                                profileImageUrl: profileImageUrl,
                              ),
                              onUnfollowTap: () => showUnfollowDialog(
                                context,
                                username: username,
                                profileImageUrl: profileImageUrl,
                                onConfirm: () => actionNotifier.toggleFollow(
                                  context,
                                  username: username,
                                  profileImageUrl: profileImageUrl,
                                ),
                              ),
                              onSendRequestTap: () =>
                                  actionNotifier.sendFollowRequest(),
                              onAnnouncementTap: handleAnnouncementPress,
                            ),
                          ],
                          if (commonFollowers.isNotEmpty)
                            SizedBox(height: 12.h),
                          FollowedBySection(commonFollowers: commonFollowers),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    delegate: ProfileSectionHeaderDelegate(
                      child: ProfileTabBar(
                        currentIndex: selectedTabIndex.value,
                        onTabSelected: onTabSelected,
                      ),
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: PageView(
                controller: pageController,
                onPageChanged: (index) {
                  selectedTabIndex.value = index;
                  unawaited(
                    getIt<AnalyticsService>().logSelectProfileSegment(
                      SelectProfileSegmentAnalyticsConfig(
                        segment: ProfileSegmentEnum.values[index],
                      ),
                    ),
                  );
                },
                children: [
                  if (!isPrivateAccount || isFollowing) ...[
                    ProfileGridTab(
                      pinnedPosts: pinnedPosts,
                      activePosts: activePosts,
                      onPinChanged: (postId, isPinned) {},
                    ),
                    ProfileEventsTab(
                      currentEvents: currentEvents,
                      consideredEvents: consideredEvents,
                      isLoading: isLoadingEvents,
                    ),
                    const ProfileDumpTab(),
                  ] else
                    const PrivateAccountView(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
