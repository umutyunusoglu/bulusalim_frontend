// lib/screens/bottom_nav/bottomnav_screen.dart

import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/constants/constant.dart';
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
  // Bu değişkenler, widget'ın o anki durumunu temsil eder.
  bool _isLoading = true; // Sayfa ilk açıldığında yükleme modunda başla
  String? _error; // Olası bir hata mesajını tutmak için
  int _currentIndex = 0; // Seçili olan sekmenin indeksi
  List<Widget> _orderedPages = []; // Firebase'den gelecek sıralı sayfalar
  List<IconData> _orderedIcons = []; // Firebase'den gelecek sıralı ikonlar

  // Firebase'deki key'ler ile Sayfa/İkon eşleştirmesi
  final Map<String, Widget> _allPages = {
    'map_page': const MapPage(),
    'search_page': const SearchPage(),
    'home_page': const HomePage(),
    'chat_page': const ChatPage(),
    'profile_page': const ProfilePage(),
  };

  final Map<String, IconData> _allIcons = {
    'map_page': Icons.map,
    'search_page': Icons.search,
    'home_page': Icons.home,
    'chat_page': Icons.chat,
    'profile_page': Icons.person,
  };

  @override
  void initState() {
    super.initState();
    // veriyi yükleme fonksiyonunu tetikler
    _loadNavConfig();
  }

  /// Firebase Remote Config'ten navigasyon verisini çeker,
  /// parse eder ve sıralar.
  Future<void> _loadNavConfig() async {
    try {
      // 1. Veriyi çek
      final remoteConfigService = getIt<RemoteConfigService>();
      await remoteConfigService.init();
      final jsonString = await remoteConfigService.getValue<String>(
        'navbar_order',
      );

      //  parser fonksiyonu
      final result = parseAndSortNavConfig(
        jsonString: jsonString,
        allPages: _allPages,
        allIcons: _allIcons,
      );
      var homeIndex = result.pages.indexWhere((page) => page is HomePage);
      if (homeIndex == -1) {
        homeIndex = 0;
      }
      // 3. Başarılı: setState() ile hafızayı güncelle
      setState(() {
        _orderedPages = result.pages;
        _orderedIcons = result.icons;
        _isLoading = false;
        _error = null;
        _currentIndex = homeIndex;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Kullanıcı bir sekmeye tıkladığında bu fonksiyon çalışır.
  void _onItemTapped(int index) {
    // Sadece _currentIndex'i güncellemek için setState çağır.
    // Bu, 'build' metodunu tetikler ve ekran güncellenir.
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Durum 1: Yükleniyor
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Durum 2: Hata
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Hata: Menü yüklenemedi.\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    // Durum 3: Başarılı
    return Scaffold(
      // Gövde:
      // IndexedStack, sayfalar arası geçişte sayfaların durumunu(scroll pozisyonu) korur
      body: IndexedStack(
        index: _currentIndex,
        children: _orderedPages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,

        type: BottomNavigationBarType.fixed,
        selectedItemColor: kBlueColor,
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: false,
        showUnselectedLabels: false,

        // İkonlar:
        items: _orderedIcons.map((iconData) {
          return BottomNavigationBarItem(
            icon: Icon(iconData, size: 26),
            label: '',
          );
        }).toList(),
      ),
    );
  }
}
