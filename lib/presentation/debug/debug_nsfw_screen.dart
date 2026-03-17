import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/domain/services/security_service.dart';

class NsfwDebugScreen extends StatefulWidget {
  const NsfwDebugScreen({super.key});

  @override
  State<NsfwDebugScreen> createState() => _NsfwDebugScreenState();
}

class _NsfwDebugScreenState extends State<NsfwDebugScreen> {
  // GetIt ile servisi çağırıyoruz
  final SecurityService _securityService = getIt<SecurityService>();

  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, double>? _results; // Sonuçları tutacak değişken
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndAnalyze() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo == null) return;

      setState(() {
        _selectedImage = File(photo.path);
        _isAnalyzing = true;
        _results = null; // Önceki sonucu temizle
      });

      // Yeni yazdığımız detaylı analiz metodunu çağırıyoruz
      final results = await _securityService.analyzeImageScores(
        _selectedImage!,
      );

      setState(() {
        _results = results;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // NSFW skoru %50'den büyükse tehlikeli kabul edelim (UI rengi için)
    bool isDanger = (_results?['nsfw'] ?? 0) > (_results?['normal'] ?? 1);

    return Scaffold(
      appBar: AppBar(title: const Text('NSFW Model Debugger (ONNX)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Resim Alanı
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
                image: _selectedImage != null
                    ? DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
              child: _selectedImage == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 50, color: Colors.grey),
                          Text('Fotoğraf Seçilmedi'),
                        ],
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 20),

            // Buton veya Yükleniyor
            if (_isAnalyzing)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickAndAnalyze,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Galeriden Seç ve Analiz Et'),
                ),
              ),

            const SizedBox(height: 30),

            // Sonuç Alanı
            if (_results != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDanger ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDanger ? Colors.red : Colors.green,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      isDanger ? 'DURUM: RİSKLİ (NSFW) 🔞' : 'DURUM: GÜVENLİ ✅',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDanger
                            ? Colors.red.shade800
                            : Colors.green.shade800,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    _buildScoreRow(
                      'Normal',
                      _results!['normal']!,
                      Colors.green,
                    ),
                    const SizedBox(height: 15),
                    _buildScoreRow('NSFW', _results!['nsfw']!, Colors.red),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, double score, Color color) {
    // Score 0.0 - 1.0 arasında gelir. Yüzdeye çevirelim.
    final percentage = (score * 100).toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '%$percentage',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score,
            minHeight: 10,
            backgroundColor: Colors.grey[300],
            color: color,
          ),
        ),
      ],
    );
  }
}
