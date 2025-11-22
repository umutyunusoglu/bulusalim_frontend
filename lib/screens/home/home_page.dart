import 'package:bulusalim/components/custom_tab_bar.dart';
import 'package:bulusalim/components/header.dart';
import 'package:bulusalim/core/constants/constant.dart';
import 'package:bulusalim/core/enums/feed_type.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            /// Üst başlık
            Header(
              title: Image.asset('assets/bulusalim.png', height: 40.h),
              trailing: Icon(
                Icons.notifications_none_outlined,
                color: kBlueColor,
                size: 25.sp,
              ),
            ),

            /// Sekme Bar
            CustomTabBar(
              currentIndex: _currentPage,
              tabs: _tabs,
              onTabSelected: (index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),

            SizedBox(height: 5.h),

            /// Sayfa içeriği
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

            // alt sayfa gösterge
            /*
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_tabs.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 5.w),
                  height: 6.h,
                  width: _currentPage == index ? 20.w : 6.w,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? kBlueColor
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                );
              }),
            ),*/
          ],
        ),
      ),
    );
  }
}

class SenlikPage extends StatelessWidget {
  const SenlikPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeContentPage(feedType: FeedType.forYou);
  }
}

class ArkadaslarinPage extends StatelessWidget {
  const ArkadaslarinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeContentPage(feedType: FeedType.friendsOnly);
  }
}
