import 'package:outnest/components/custom_tab_bar.dart';
import 'package:outnest/components/header.dart';
import 'package:outnest/core/utils/types/enums/feed_type.dart';
import 'package:outnest/screens/home/home_content_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();

  // Hangi sekmenin seçili olduğunu tutan değişken (0: Senlik, 1: Arkadaşların, 2: Okul)
  int _currentPage = 0;

  // Sekme İsimleri
  final List<String> _tabs = ['Senlik', 'Arkadaşların', 'Okul'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToCamera() {
    context.push('/camera');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // KATMAN 1: ANA İÇERİK (Header + Sayfalar)
            Column(
              children: [
                // --- HEADER ve TAB BAR BİRLEŞİMİ ---
                Header(
                  // Header'ın orta kısmına CustomTabBar'ı gönderiyoruz
                  middleWidget: CustomTabBar(
                    currentIndex: _currentPage, // Şu anki sayfa no
                    tabs: _tabs, // İsim listesi
                    onTabSelected: (index) {
                      // Tab'a tıklanınca:
                      setState(() => _currentPage = index); // Rengi güncelle
                      _pageController.animateToPage(
                        // Sayfayı kaydır
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  // trailing: null, // İstersen sağdaki ikonu buradan değiştirebilirsin
                ),

                SizedBox(height: 10.h), // Header ile İçerik arası boşluk
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      // Sayfa elle kaydırılınca tab rengini güncelle
                      setState(() => _currentPage = index);
                    },
                    children: const [
                      // 1. Sayfa: Senlik
                      HomeContentPage(feedType: FeedType.forYou),

                      // 2. Sayfa: Arkadaşların
                      HomeContentPage(feedType: FeedType.friendsOnly),

                      // 3. Sayfa: Okul (Şimdilik boş bir text koydum)
                      Center(child: Text('Okul Akışı Yakında...')),
                      //HomeContentPage(feedType: FeedType.forYou),
                    ],
                  ),
                ),
              ],
            ),

            // KATMAN 2: KAMERA BUTONU (Sağ Alt)
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
