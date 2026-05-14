// presentation/home/view/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/analytics/event_configs/select_feed_analytics_config.dart';
import 'package:outnest/presentation/home/view/components/custom_tab_bar.dart';
import 'package:outnest/presentation/home/view/components/header.dart';
import 'package:outnest/presentation/home/view/home_content_page.dart';
import 'package:outnest/presentation/shared/action_buttons_speed_dial.dart';
import 'package:outnest/presentation/shared/dialogs/city_selection_dialog.dart';
import 'package:outnest/presentation/shared/navigation/navigate_to_camera.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pageController = usePageController();
    final currentPage = useState(0);
    final isDialOpen = useValueNotifier(false);
    final tabs = ['Senlik', 'Arkadaşların', 'Okul'];

    ref.listen(currentUserEntityProvider, (previous, next) {
      next.whenData((user) {
        if (previous?.value?.city == null && user?.city == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const CitySelectionDialog(isDismissible: false),
            );
          });
        }
      });
    });

    void onTabSelected(int index) {
      getIt<AnalyticsService>().logSelectFeed(
        SelectFeedAnalyticsConfig(
          value: FeedType.values[index],
          previousValue: FeedType.values[currentPage.value],
        ),
      );
      currentPage.value = index;
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    void onPageChanged(int index) {
      getIt<AnalyticsService>().logSelectFeed(
        SelectFeedAnalyticsConfig(
          value: FeedType.values[index],
          previousValue: FeedType.values[currentPage.value],
        ),
      );
      currentPage.value = index;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Header(
              middleWidget: CustomTabBar(
                currentIndex: currentPage.value,
                tabs: tabs,
                onTabSelected: onTabSelected,
              ),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: PageView(
                controller: pageController,
                onPageChanged: onPageChanged,
                children: const [
                  HomeContentPage(feedType: FeedType.all),
                  HomeContentPage(feedType: FeedType.friendsOnly),
                  HomeContentPage(feedType: FeedType.university),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ValueListenableBuilder(
        valueListenable: isDialOpen,
        builder: (context, isOpen, _) {
          return ActionButtonsSpeedDial(
            isDialOpen: isDialOpen,
            onCameraTap: () => navigateToCamera(context, ref),
            onLocationTap: () => context.go('/map', extra: true),
            onQrTap: () => context.push('/my-qr'),
            onIdeaTap: () => context.push('/create-idea'),
          );
        },
      ),
    );
  }
}
