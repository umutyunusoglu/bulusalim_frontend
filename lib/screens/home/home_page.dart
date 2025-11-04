import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bulusalim/core/constants/constant.dart';
import 'package:bulusalim/components/header.dart';
import 'package:bulusalim/components/custom_tab_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
              ),
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
    return const Center(
      child: Text(
        "🎉 Senlik Sayfası ",
        style: TextStyle(fontSize: 16),
      ),
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

/*
import 'package:bulusalim/components/header.dart';
import 'package:bulusalim/core/constants/constant.dart';
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
              /// Header
              Header(
                title: Image.asset('assets/bulusalim.png', height: 40.h),
                trailing: Icon(
                  Icons.notifications_none_outlined,
                  color: kBlueColor,
                  size: 25.sp,
                ),
              ),

              SizedBox(height: 20.h),

              /// Sekme + indicator'ı bir LayoutBuilder içinde yapıyoruz
              LayoutBuilder(
                builder: (context, constraints) {
                  // toplam kullanılabilir genişlik
                  final totalWidth = constraints.maxWidth;
                  // sekme sayısı
                  const tabCount = 2;
                  // her bir tab genişliği
                  final tabWidth = totalWidth / tabCount;
                  // indicator genişliği: tabWidth'in %60'ı ama max 140.w
                  final indicatorWidth = (tabWidth * 0.6).clamp(40.w, 140.w);

                  // indicator'ın sol offseti (selectedIndex'e göre)
                  final leftOffset =
                      _currentPage * tabWidth + (tabWidth - indicatorWidth) / 2;

                  return Column(
                    children: [
                      // Sekme başlıkları (her biri eşit genişlikte)
                      Row(
                        children: [
                          _tabItem("Senlik", 0, width: tabWidth),
                          _tabItem("Arkadaşların", 1, width: tabWidth),
                        ],
                      ),

                      SizedBox(height: 8.h),

                      // Divider + indicator (indicator Positioned ile hizalanıyor)
                      Stack(
                        children: [
                          // Gri divider full width
                          Container(
                            height: 3.5.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.4),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),

                          // Animated Positioned indicator
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeInOut,
                            left: leftOffset,
                            top: 0,
                            child: Container(
                              width: indicatorWidth,
                              height: 3.h,
                              decoration: BoxDecoration(
                                color: kBlueColor,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: 10.h),

              /// PageView (swipe alanı), page değiştiğinde indicator da update ediliyor
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

              /// Sayfa göstergesi (alt dot)
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) {
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabItem(String title, int index, {required double width}) {
    final isActive = _currentPage == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage = index);
      },
      child: SizedBox(
        width: width,
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive ? kBlueColor : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder sayfalar
class SenlikPage extends StatelessWidget {
  const SenlikPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Senlik Sayfası"));
  }
}

class ArkadaslarinPage extends StatelessWidget {
  const ArkadaslarinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Arkadaşların Sayfası"));
  }
}
//DİVIDER
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Divider(
                  height: 2.h,
                  thickness: 1.2,
                  color: Colors.grey.shade400,
                ),
              ), */
