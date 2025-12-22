import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavbar extends StatelessWidget {
  const ScaffoldWithNavbar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavbar'));

  // Bu değişken, şu an hangi sekmede olduğumuzu ve navigasyon durumunu tutar
  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // Kullanıcı zaten olduğu sekmeye tekrar tıklarsa, o sekmeyi en başa sar (Örn: Feed'in en tepesine çık)
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Body artık dinamik! GoRouter buraya Home, Map veya Profil sayfasını kendisi koyacak.
      body: navigationShell,

      bottomNavigationBar: Container(
        // Senin tasarımındaki o ince üst çizgi detayı
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _goBranch,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedItemColor: theme.colorScheme.tertiary,
          unselectedItemColor: theme.textTheme.bodyMedium?.color?.withOpacity(
            0.5,
          ),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,

          // DİKKAT: Bu sıra, Router'daki branch sırasıyla AYNI OLMALIDIR.
          items: const [
            // 1. Map (Harita)
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined, size: 25),
              label: 'Map',
            ),

            // 2. Search (Arama) - İstersen buraya 'Icons.search' yerine elindeki SVG'yi de koyabilirsin
            BottomNavigationBarItem(
              icon: Icon(Icons.search, size: 25),
              label: 'Search',
            ),

            // 3. Home (Ana Sayfa) - ORTADA
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 25),
              label: 'Home',
            ),

            // 4. Chat (Sohbet)
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline, size: 25),
              label: 'Chat',
            ),

            // 5. Profile (Profil)
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 25),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
