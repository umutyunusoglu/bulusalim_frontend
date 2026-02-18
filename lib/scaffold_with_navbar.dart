import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outnest/application/providers/get_it_init.dart'; // GetIt'i import etmeyi unutma!

class ScaffoldWithNavbar extends StatelessWidget {
  const ScaffoldWithNavbar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    // Eğer şu an Home'daysak (2) VE tekrar Home'a (2) basıldıysa...
    if (navigationShell.currentIndex == 2 && index == 2) {
      // GetIt'teki sinyali tetikle (Sayıyı arttır)
      // Bu sinyal HomeContentPage'deki dinleyiciyi çalıştıracak.
      getIt<ValueNotifier<int>>(instanceName: 'homeScrollTrigger').value++;
    } else {
      // Diğer durumlar için standart GoRouter geçişi yap
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(),
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
          items: const [
            // Index 0: Map
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined, size: 25),
              label: 'Map',
            ),
            // Index 1: Search
            BottomNavigationBarItem(
              icon: Icon(Icons.search, size: 25),
              label: 'Search',
            ),
            // Index 2: Home
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 25),
              label: 'Home',
            ),
            // Index 3: Chat
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline, size: 25),
              label: 'Chat',
            ),
            // Index 4: Profile
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
