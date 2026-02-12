import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/data/services/security_service_impl.dart';
import 'package:outnest/domain/services/security_service.dart';
// Kendi dosya yollarınla güncelle:

class NsfwDebugScreen extends StatefulWidget {
  NsfwDebugScreen({super.key});
  final SecurityService securityService = getIt<SecurityService>();

  @override
  State<NsfwDebugScreen> createState() => _NsfwDebugScreenState();
}

class _NsfwDebugScreenState extends State<NsfwDebugScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, double>? _lastResults;
  bool? _isSafe;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndAnalyze() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);

    if (photo == null) return;

    setState(() {
      _selectedImage = File(photo.path);
      _isAnalyzing = true;
      _lastResults = null;
      _isSafe = null;
    });

    // Not: SecurityServiceImpl içinde sonuçları Map olarak döndüren
    // veya loglayan bir debug metodu eklemek iyi olabilir.
    // Şimdilik isImageSafe üzerinden gidelim:
    final bool safe = await widget.securityService.isImageSafe(_selectedImage!);

    setState(() {
      _isSafe = safe;
      _isAnalyzing = false;
      // Not: Tam skorları görmek için SecurityServiceImpl içindeki
      // results map'ini bir değişkene çıkarıp buraya paslayabilirsin.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NSFW Model Debugger")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_selectedImage != null)
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  image: DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              const Center(child: Text("Lütfen bir fotoğraf seçin")),

            const SizedBox(height: 20),

            if (_isAnalyzing)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _pickAndAnalyze,
                icon: const Icon(Icons.photo_library),
                label: const Text("Galeriden Seç ve Analiz Et"),
              ),

            const SizedBox(height: 30),

            if (_isSafe != null) ...[
              Text(
                _isSafe! ? "DURUM: GÜVENLİ ✅" : "DURUM: RİSKLİ ❌",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _isSafe! ? Colors.green : Colors.red,
                ),
              ),
              const Divider(height: 40),
              const Text(
                "Model Tahminleri (Eşik Değerleri)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Eğer SecurityServiceImpl'da results'ı dışarı açtıysan buraya ProgressBar'lar eklenebilir.
              _buildScoreBar("Porn", 0.4), // Örnek eşik gösterimi
              _buildScoreBar("Sexy", 0.8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, double threshold) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label (Threshold: $threshold)"),
          LinearProgressIndicator(value: threshold, color: Colors.orange),
        ],
      ),
    );
  }
}
