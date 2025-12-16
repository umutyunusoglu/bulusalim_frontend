import 'package:bulusalim/components/custom_tab_bar.dart';
import 'package:bulusalim/components/header.dart';
import 'package:bulusalim/core/utils/types/enums/feed_type.dart';
import 'package:bulusalim/screens/camera/splash_screen.dart';
import 'package:bulusalim/screens/home/home_content_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _tabs = ['Senlik', 'Arkadaşların'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToCamera() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (context) => const CameraSplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TEMA BAĞLANTISI
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // KATMAN 1: ANA İÇERİK
            Column(
              children: [
                /// Üst Başlık (Header)
                Header(
                  title: Image.asset(
                    'assets/bulusalim.png',
                    height: 40.h,
                  ),
                  trailing: Icon(
                    Icons.notifications_none_outlined,
                    color: iconColor,
                    size: 28.sp,
                  ),
                ),

                /// Sekme Bar (TabBar)
                CustomTabBar(
                  currentIndex: _currentPage,
                  tabs: _tabs,
                  onTabSelected: (index) {
                    setState(() => _currentPage = index);
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),

                SizedBox(height: 5.h),

                /// Sayfa İçeriği (PageView)
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: const [
                      SenlikPage(),
                      ArkadaslarinPage(),
                    ],
                  ),
                ),
              ],
            ),

            // KATMAN 2: FOTOĞRAF ÇEKME BUTONU (Custom FAB)
            Positioned(
              right: 16.w,
              bottom: 14.h,
              child: GestureDetector(
                onTap: _navigateToCamera,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/group103.png',
                    width: 62.w,
                    height: 90.w,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// "Senlik" Akışı
class SenlikPage extends StatelessWidget {
  const SenlikPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeContentPage(feedType: FeedType.forYou);
  }
}

// "Arkadaşların" Akışı
class ArkadaslarinPage extends StatelessWidget {
  const ArkadaslarinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeContentPage(feedType: FeedType.friendsOnly);
  }
}
