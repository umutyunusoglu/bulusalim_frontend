import 'dart:convert';
import 'package:bulusalim/core/constants/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

// 🔹 Sayfalar import edilecek (şimdilik örnek)
import 'package:bulusalim/screens/chat/chat_page.dart';
import 'package:bulusalim/screens/home/home_page.dart';
import 'package:bulusalim/screens/map/map_page.dart';
import 'package:bulusalim/screens/profile/profile_page.dart';
import 'package:bulusalim/screens/search/search_page.dart';

/// --- PROVIDERLAR ---

// Remote Config’ten veri çekme
final remoteConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.fetchAndActivate();

  // Remote Config key ismi: "navbar_order"
  final jsonString = remoteConfig.getString('navbar_order');
  if (jsonString.isEmpty) {
    throw Exception('Remote Config verisi bulunamadı.');
  }
  return jsonDecode(jsonString) as Map<String, dynamic>;
});

// Aktif index tutan provider
final currentIndexProvider = StateProvider<int>((ref) => 0);

/// --- ANA WIDGET ---

class CustomNavBar extends ConsumerWidget {
  CustomNavBar({super.key});

  // Sayfalar listesi
  final List<Widget> pages = [
    const MapPage(),
    const SearchPage(),
    const HomePage(),
    const ChatPage(),
    const ProfilePage(),
  ];

  // Icon listesi
  final List<IconData> icons = [
    Icons.map,
    Icons.search,
    Icons.home,
    Icons.chat,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remoteConfigAsync = ref.watch(remoteConfigProvider);
    final currentIndex = ref.watch(currentIndexProvider);

    return remoteConfigAsync.when(
      data: (orderMap) {
        /// Firebase’ten gelen sıraya göre diziyi oluştur
        final entries = orderMap.entries.toList()
          ..sort((a, b) {
            final aVal = a.value;
            final bVal = b.value;
            final int ai = (aVal is num)
                ? aVal.toInt()
                : int.tryParse(aVal.toString()) ?? 0;
            final int bi = (bVal is num)
                ? bVal.toInt()
                : int.tryParse(bVal.toString()) ?? 0;
            return ai.compareTo(bi);
          });

        final orderedIcons = entries.map((e) {
          final keyIndex = orderMap.keys.toList().indexOf(e.key);
          return icons[keyIndex];
        }).toList();

        final orderedPages = entries.map((e) {
          final keyIndex = orderMap.keys.toList().indexOf(e.key);
          return pages[keyIndex];
        }).toList();

        return Scaffold(
          backgroundColor: Colors.white,
          body: orderedPages[currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            onTap: (index) {
              ref.read(currentIndexProvider.notifier).state = index;
            },
            selectedItemColor: kBlueColor,
            unselectedItemColor: Colors.grey.shade600,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: [
              for (var icon in orderedIcons)
                BottomNavigationBarItem(
                  icon: Icon(icon, size: 26),
                  label: '',
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Hata: $err')),
    );
  }
}
