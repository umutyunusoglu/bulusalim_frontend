import 'package:bulusalim/components/custom_tab_bar.dart';
import 'package:bulusalim/components/header.dart';
import 'package:bulusalim/core/constants/constant.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/repositories/post_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _HomePageState();
}

class _HomePageState extends State<MapPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _tabs = ["Senlik", "Arkadaşların"];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
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

              SizedBox(height: 20.h),

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
                  setState(() => _currentPage = index);
                },
              ),

              SizedBox(height: 10.h),

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

              /// Alt sayfa göstergesi
              /*SizedBox(height: 10.h),
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
      ),
    );
  }
}

/// Şimdilik placeholder sayfalar
class SenlikPage extends StatelessWidget {
  const SenlikPage({super.key});

  @override
  Widget build(BuildContext context) {
    final postRepository = GetIt.instance<PostRepository>();
    final logger = GetIt.instance<LoggingService>();

    return FutureBuilder(
      future: postRepository.getAllPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty || posts[0].imageUrls!.isEmpty) {
          return const Center(child: Text("No posts available"));
        }

        final postPhotoUrl = posts[0].imageUrls!.first;
        logger.debug(postPhotoUrl);

        return Center(
          child: Image.network(
            postPhotoUrl,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

class ArkadaslarinPage extends StatelessWidget {
  const ArkadaslarinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "👫 Arkadaşların Sayfası",
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
