import 'dart:async'; // Timer için gerekli
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/screens/profile/profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Controller ve State değişkenleri
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<QueryDocumentSnapshot> _userResults = [];
  List<QueryDocumentSnapshot> _eventResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel(); // Memory leak önlemek için timer'ı kapatıyoruz
    super.dispose();
  }

  // Arama Mantığı
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Kullanıcı yazmayı bıraktıktan 300ms sonra çalışır (Debounce)
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _userResults = [];
          _eventResults = [];
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    // DİKKAT: Veritabanında 'search_name' veya 'name' alanının küçük harfli hali olmalı.
    // Case sensitivity sorununu aşmak için query'yi küçültüyoruz.
    final searchTerm = query.toLowerCase();

    try {
      final userRef = FirebaseFirestore.instance.collection('public_users');
      final eventRef = FirebaseFirestore.instance.collection('events');

      // İki tabloyu paralel (aynı anda) sorguluyoruz
      final results = await Future.wait([
        userRef
            .orderBy('username') // Varsa 'search_name' kullan
            .startAt([searchTerm])
            .endAt(['$searchTerm\uf8ff'])
            .get(),
        eventRef
            .orderBy('username') // Varsa 'search_name' kullan
            .startAt([searchTerm])
            .endAt(['$searchTerm\uf8ff'])
            .get(),
      ]);

      if (mounted) {
        setState(() {
          _userResults = results[0].docs;
          _eventResults = results[1].docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Arama Hatası: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arama'),
      ),
      body: Column(
        children: [
          // 1. Arama Çubuğu
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Kullanıcı veya buluşma ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 2. Yükleniyor veya Sonuç Listesi
          if (_isLoading)
            const LinearProgressIndicator()
          else
            Expanded(
              child: ListView(
                children: [
                  // --- Kullanıcı Sonuçları ---
                  if (_userResults.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'KULLANICILAR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ..._userResults.map((doc) {
                      final data = doc.data()! as Map<String, dynamic>;
                      final rawProfileUrl = data['profileImageUrl'] as String?;
                      final hasUrl =
                          rawProfileUrl != null &&
                          rawProfileUrl.isNotEmpty &&
                          rawProfileUrl.startsWith('http');

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          // URL varsa CachedNetworkImageProvider, yoksa (veya boşsa) asset resmimiz
                          backgroundImage: hasUrl
                              ? CachedNetworkImageProvider(
                                  fixEmulatorUrl(rawProfileUrl),
                                )
                              : AssetImage(FileService.defaultProfileImageUrl())
                                    as ImageProvider,
                          onBackgroundImageError: (_, __) =>
                              debugPrint('ListTile Avatar Error'),
                        ),
                        title: Text(
                          data['username'] as String? ?? 'İsimsiz',
                        ),
                        onTap: () {
                          // Klavye açıksa kapat
                          FocusScope.of(context).unfocus();

                          // ProfilePage sayfasına yönlendir
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfilePage(profileUserID: doc.id),
                            ),
                          );
                        },
                      );
                    }),
                  ],

                  // --- buluşma Sonuçları ---
                  if (_eventResults.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'ETKİNLİKLER',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ..._eventResults.map((doc) {
                      final data = doc.data()! as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(Icons.event, color: Colors.purple),
                        title: Text(
                          data['username'] as String? ?? 'Adsız Buluşma',
                        ),
                        onTap: () => debugPrint('Tıklandı: Event ${doc.id}'),
                      );
                    }),
                  ],

                  // --- Sonuç Yoksa ---
                  if (_userResults.isEmpty &&
                      _eventResults.isEmpty &&
                      _searchController.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('Sonuç bulunamadı.')),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
