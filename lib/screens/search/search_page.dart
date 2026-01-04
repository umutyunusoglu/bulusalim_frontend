import 'dart:async'; // Timer için gerekli
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
      final userRef = FirebaseFirestore.instance.collection('users');
      final eventRef = FirebaseFirestore.instance.collection('events');

      // İki tabloyu paralel (aynı anda) sorguluyoruz
      final results = await Future.wait([
        userRef
            .orderBy('search_name') // Varsa 'search_name' kullan
            .startAt([searchTerm])
            .endAt(['$searchTerm\uf8ff'])
            .get(),
        eventRef
            .orderBy('search_name') // Varsa 'search_name' kullan
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
        title: const Text('Debug Search'),
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
                hintText: 'Kullanıcı veya Etkinlik ara...',
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
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(
                          data['search_name'] as String? ?? 'İsimsiz',
                        ),
                        subtitle: Text(doc.id), // Debug için ID görmek iyidir
                        onTap: () => debugPrint('Tıklandı: User ${doc.id}'),
                      );
                    }),
                  ],

                  // --- Etkinlik Sonuçları ---
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
                          data['search_name'] as String? ?? 'Adsız Etkinlik',
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
