import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_friend_providers.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/application/profile/profile_notifier.dart';
import 'package:outnest/application/profile/profile_providers.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/core/utils/types/enums/profile_segment_enum.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/feed/post/post_entity.dart';
import 'package:outnest/domain/entities/user/index.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/analytics/event_configs/select_profile_segment_analytics_config.dart';
import 'package:outnest/presentation/profile/view/community_info_page.dart';
import 'package:outnest/presentation/profile/view/components/common_members_row.dart';
import 'package:outnest/presentation/profile/view/components/community_bottom_sheet.dart';
import 'package:outnest/presentation/profile/view/components/dump_tab.dart';
import 'package:outnest/presentation/profile/view/components/events_tab.dart';
import 'package:outnest/presentation/profile/view/components/grid_tab.dart';
import 'package:outnest/presentation/profile/view/components/profile_section_header_delegate.dart';
import 'package:outnest/presentation/profile/view/components/profile_stat_item.dart';
import 'package:outnest/presentation/profile/view/components/profile_tab_bar.dart';
import 'package:outnest/presentation/shared/login_button.dart';
import 'package:outnest/presentation/shared/popup.dart';

class CommunityProfilePage extends HookConsumerWidget {
  const CommunityProfilePage({required this.profileUserID, super.key});

  final String profileUserID;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final selectedTabIndex = useState(0);

    // ─── Current user ────────────────────────────────────────
    final myUserId = ref.watch(currentUserIDProvider);
    final currentUser = ref.watch(currentUserEntityProvider).value;
    final isCurrentUser = profileUserID == myUserId;

    // ─── Profile data (mevcut provider'lar aynen kullanılıyor) ─
    final communityUserAsync = ref.watch(profileUserProvider(profileUserID));
    final postsAsync = ref.watch(profilePostsProvider(profileUserID));
    final statsAsync = ref.watch(profileStatsProvider(profileUserID));
    final eventsAsync = ref.watch(profileEventsProvider(profileUserID));
    final commonMembers =
        ref.watch(profileCommonFollowersProvider(profileUserID)).value ?? [];

    // ─── Session-based (üyelik durumu için) ──────────────────
    final myFollowees = ref.watch(currentUserFolloweesProvider).value ?? [];

    // ─── Action notifier ─────────────────────────────────────
    final actionNotifier = ref.read(
      profileActionProvider(profileUserID).notifier,
    );

    // ─── Loading ─────────────────────────────────────────────
    if (communityUserAsync.isLoading || communityUserAsync.value == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = communityUserAsync.value;

    // ─── Derived fields ──────────────────────────────────────
    final username = isCurrentUser
        ? (currentUser?.username ?? '')
        : '${user.username ?? ''}';
    final fullName = isCurrentUser
        ? (currentUser?.nameSurname ?? '')
        : '${user.nameSurname ?? ''}';
    final bio = isCurrentUser ? (currentUser?.bio ?? '') : '${user.bio ?? ''}';
    final school = isCurrentUser
        ? (currentUser?.university ?? 'Üniversite Doğrulanmadı')
        : '${user.university ?? 'Üniversite Doğrulanmadı'}';
    final profileImageUrl = isCurrentUser
        ? (currentUser?.profileImageUrl ?? '')
        : '${user.profileImageUrl ?? ''}';
    final displayTitle = fullName.isNotEmpty ? fullName : username;

    // ─── Membership status (= follow status) ─────────────────
    final isMember =
        isCurrentUser || myFollowees.any((f) => f.userID == profileUserID);

    // ─── Stats ───────────────────────────────────────────────
    final stats = statsAsync.value;
    final numberOfEvents = stats?.events ?? 0;
    final memberCount = stats?.followers ?? 0;

    // ─── Posts ───────────────────────────────────────────────
    final posts = postsAsync.value;
    final pinnedPosts = posts?.pinned ?? <PostEntity>[];
    final activePosts = posts?.active ?? <PostEntity>[];

    // ─── Events ──────────────────────────────────────────────
    final events = eventsAsync.value;
    final currentEvents = events?.current ?? <EventEntity>[];
    final consideredEvents = events?.considered ?? <EventEntity>[];
    final isLoadingEvents = eventsAsync.isLoading;

    // ─── Community data (iletişim bilgileri) ─────────────────
    final communityData =
        (isCurrentUser ? currentUser?.communityData : user.communityData)
            as CommunityData?;

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

    void showUnfollowDialog() {
      showDialog(
        context: context,
        builder: (ctx) => Popup(
          title: '$username topluluğundan ayrılmak istediğine emin misin?',
          description: 'Tekrar katılmak için istek göndermen gerekebilir.',
          confirmButtonText: 'ayrıl',
          confirmButtonColor: const Color(0xFF5D6B82),
          onConfirm: () {
            ctx.pop();
            actionNotifier.toggleFollow(
              context,
              username: username,
              profileImageUrl: profileImageUrl,
            );
          },
        ),
      );
    }

    Future<void> showFullScreenImage(
      BuildContext context,
      String imageUrl,
    ) async {
      final hasValidImage =
          imageUrl.trim().isNotEmpty && imageUrl.startsWith('http');

      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close',
        barrierColor: Colors.black.withOpacity(0.5),
        pageBuilder: (context, animation, secondaryAnimation) {
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(color: Colors.black26),
                    ),
                  ),
                  Center(
                    child: Hero(
                      tag: 'community_profile_pic_$profileUserID',
                      child: Container(
                        width: 264.w,
                        height: 264.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade100,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: hasValidImage
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.black,
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Symbols.groups,
                                    size: 120.sp,
                                    color: Colors.grey,
                                  ),
                                )
                              : Icon(
                                  Symbols.groups,
                                  size: 120.sp,
                                  color: Colors.grey,
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

    // ─── BUILD ───────────────────────────────────────────────
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final safeProfileImageUrl = profileImageUrl.isNotEmpty
        ? fixEmulatorUrl(profileImageUrl)
        : '';

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
                    Symbols.reply,
                    color: onSurface,
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
                    color: onSurface,
                  ),
                ),
              ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // ─── HEADER ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    top: isCurrentUser ? 24.h : 8.h,
                    bottom: 20.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profil foto + bilgi ────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => showFullScreenImage(
                              context,
                              safeProfileImageUrl,
                            ),
                            child: Hero(
                              tag: 'community_profile_pic_$profileUserID',
                              child: CircleAvatar(
                                radius: 38.r,
                                backgroundColor: Colors.grey.shade100,
                                backgroundImage: profileImageUrl.isNotEmpty
                                    ? CachedNetworkImageProvider(
                                        safeProfileImageUrl,
                                      )
                                    : null,
                                onBackgroundImageError:
                                    profileImageUrl.isNotEmpty
                                    ? (error, stackTrace) {
                                        debugPrint(
                                          'CommunityProfile image error: '
                                          'url=$safeProfileImageUrl '
                                          'error=$error',
                                        );
                                      }
                                    : null,
                                child: profileImageUrl.isEmpty
                                    ? Icon(
                                        Symbols.groups,
                                        size: 30.sp,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // İsim + ayarlar ikonu
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 4.h),
                                        child: Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
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
                                              Symbols.groups,
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
                                // İstatistikler
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ProfileStatItem(
                                      count: '$numberOfEvents',
                                      label: ' Etkinlik',
                                    ),
                                    ProfileStatItem(
                                      count: '$memberCount',
                                      label: ' Üye',
                                    ),
                                    const ProfileStatItem(
                                      count: '0',
                                      label: ' Etkileşim',
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                // Bio
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
                                // Üniversite
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

                      // ── Katıl + İletişim + Info ────────────
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: LoginButton(
                              label: isMember ? 'katıldın' : 'katıl',
                              onPress: () {
                                if (isMember) {
                                  showUnfollowDialog();
                                } else {
                                  actionNotifier.toggleFollow(
                                    context,
                                    username: username,
                                    profileImageUrl: profileImageUrl,
                                  );
                                }
                              },
                              height: 32.h,
                              width: double.infinity,
                              borderRadius: 20.r,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              backgroundColor: isMember
                                  ? const Color(0xFFF2F2F7)
                                  : AppColors.primaryColor,
                              textColor: isMember
                                  ? AppColors.primaryColor
                                  : Colors.white,
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
                                  builder: (_) => CommunityBottomSheet(
                                    instagram:
                                        communityData?.instagramUrl ?? '',
                                    whatsapp: communityData?.whatsappUrl ?? '',
                                    website: communityData?.websiteUrl ?? '',
                                    email: communityData?.contactEmail ?? '',
                                  ),
                                );
                              },
                              height: 32.h,
                              width: double.infinity,
                              borderRadius: 20.r,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              backgroundColor: const Color(0xFFF2F2F7),
                              textColor: AppColors.tertiaryColor,
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
                              ),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Symbols.info,
                                color: AppColors.tertiaryColor,
                                size: 20.sp,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CommunityInfoPage(
                                      communityData: communityData,
                                      nameSurname: fullName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      // ── Ortak üyeler ───────────────────────
                      if (commonMembers.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        CommonMembersRow(
                          commonMembers: commonMembers,
                          theme: theme,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ─── TAB BAR ──────────────────────────────────
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

          // ─── TAB PAGES ─────────────────────────────────────
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
            ],
          ),
        ),
      ),
    );
  }
}
