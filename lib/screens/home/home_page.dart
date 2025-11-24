import 'package:bulusalim/components/custom_tab_bar.dart';
import 'package:bulusalim/components/header.dart';
import 'package:bulusalim/core/constants/constant.dart';
import 'package:bulusalim/core/enums/feed_type.dart';
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraSplashScreen()),
    );
    debugPrint("Kamera butonuna tıklandı!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Stack'in ekranın güvenli alanları içinde kalması için SafeArea kullanıyoruz
      body: SafeArea(
        child: Stack(
          children: [
            // KATMAN 1: ANA İÇERİK (Sizin eski Column yapınız)
            Column(
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

                /// Sayfa içeriği (PageView)
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

            // KATMAN 2: FOTOĞRAF ÇEKME BUTONU (En üstte durur)
            Positioned(
              right: 6.w, // Sağdan boşluk
              bottom: 14.h, // Alttan boşluk
              child: GestureDetector(
                onTap: _navigateToCamera, // Tıklama aksiyonu
                // İsteğe bağlı gölge efekti (Resmin kendisinde gölge yoksa)
                child: Image.asset(
                  'assets/group103.png', // Sizin belirttiğiniz görsel
                  width: 62.w, // Görselin boyutu (İhtiyaca göre ayarlayın)
                  height: 80.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),
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
