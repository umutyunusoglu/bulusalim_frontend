// lib/screens/bottom_nav/bottomnav_screen.dart

import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/utils/nav_parser.dart';
import 'package:bulusalim/domain/services/remote_config_service.dart';
import 'package:bulusalim/screens/chat/chat_page.dart';
import 'package:bulusalim/screens/home/home_page.dart';
import 'package:bulusalim/screens/map/map_page.dart';
import 'package:bulusalim/screens/profile/profile_page.dart';
import 'package:bulusalim/screens/search/search_page.dart';
import 'package:flutter/material.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  List<Widget> _orderedPages = [];
  List<IconData> _orderedIcons = [];

  // Sayfa ve İkon Tanımları
  final Map<String, Widget> _allPages = {
    'map_page': const MapPage(),
    'search_page': const SearchPage(),
    'home_page': const HomePage(),
    'chat_page': const ChatPage(),
    'profile_page': const ProfilePage(),
  };

  final Map<String, IconData> _allIcons = {
    'map_page': Icons.map_outlined,
    'search_page': Icons.search,
    'home_page': Icons.home_outlined,
    'chat_page': Icons.chat_bubble_outline,
    'profile_page': Icons.person_outline,
  };

  @override
  void initState() {
    super.initState();
    _loadNavConfig();
  }

  Future<void> _loadNavConfig() async {
    try {
      final remoteConfigService = getIt<RemoteConfigService>();
      await remoteConfigService.init();

      final jsonString = await remoteConfigService.getValue<String>(
        'navbar_order',
      );

      final result = parseAndSortNavConfig(
        jsonString: jsonString,
        allPages: _allPages,
        allIcons: _allIcons,
      );

      // HomePage'i bul ve başlangıç indexi yap, yoksa 0
      var homeIndex = result.pages.indexWhere((page) => page is HomePage);
      if (homeIndex == -1) homeIndex = 0;

      if (mounted) {
        setState(() {
          _orderedPages = result.pages;
          _orderedIcons = result.icons;
          _isLoading = false;
          _error = null;
          _currentIndex = homeIndex;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TEMA BAĞLANTISI
    final theme = Theme.of(context);

    // Durum 1: Yükleniyor
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.secondary,
          ),
        ),
      );
    }

    // Durum 2: Hata
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Menü yüklenemedi. Lütfen internetinizi kontrol edin.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Durum 3: Başarılı
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _orderedPages,
      ),
      bottomNavigationBar: Container(
        // Üstüne ince bir çizgi ekleyerek ayrımı netleştiriyoruz
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedItemColor: theme.colorScheme.tertiary,

          unselectedItemColor: theme.textTheme.bodyMedium?.color?.withOpacity(
            0.5,
          ),

          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: _orderedIcons.map((iconData) {
            return BottomNavigationBarItem(
              icon: Icon(iconData, size: 25),
              label: '',
            );
          }).toList(),
        ),
      ),
    );
  }
}
