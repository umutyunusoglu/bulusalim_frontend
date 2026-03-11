import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/analytics/event_configs/select_feed_analytics_config.dart';
import 'package:outnest/presentation/home/view/components/custom_tab_bar.dart';
import 'package:outnest/presentation/home/view/components/header.dart';
import 'package:outnest/presentation/home/view/home_content_page.dart';
import 'package:outnest/presentation/shared/action_buttons_speed_dial.dart';
import 'package:outnest/presentation/shared/navigation/navigate_to_camera.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _tabs = ['Senlik', 'Arkadaşların', 'Okul'];

  final ValueNotifier<bool> isDialOpen = ValueNotifier(false);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Header(
                  middleWidget: CustomTabBar(
                    currentIndex: _currentPage,
                    tabs: _tabs,
                    onTabSelected: (index) {
                      final previousFeedType = FeedType.values[_currentPage];
                      final newFeedType = FeedType.values[index];
                      getIt<AnalyticsService>().logSelectFeed(
                        SelectFeedAnalyticsConfig(
                          value: newFeedType,
                          previousValue: previousFeedType,
                        ),
                      );

                      setState(() => _currentPage = index);

                      setState(() => _currentPage = index);
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      final previousFeedType = FeedType.values[_currentPage];
                      final newFeedType = FeedType.values[index];
                      getIt<AnalyticsService>().logSelectFeed(
                        SelectFeedAnalyticsConfig(
                          value: newFeedType,
                          previousValue: previousFeedType,
                        ),
                      );

                      setState(() => _currentPage = index);
                    },
                    children: const [
                      HomeContentPage(feedType: FeedType.all),
                      HomeContentPage(feedType: FeedType.friendsOnly),
                      HomeContentPage(feedType: FeedType.university),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: ValueListenableBuilder(
        valueListenable: isDialOpen,
        builder: (context, isOpen, _) {
          return ActionButtonsSpeedDial(
            isDialOpen: isDialOpen,
            onCameraTap: () => navigateToCamera(context),
            onLocationTap: () {
              context.go('/map', extra: true);
            },
          );
        },
      ),
    );
  }
}
