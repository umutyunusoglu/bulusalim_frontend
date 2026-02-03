import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/draft_post_service.dart';
import 'package:outnest/screens/camera/new_post_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({required this.event, super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
  final EventEntity event;
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<File> _takenPhotos = [];
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0; // Arka/Ön kamera değişimi için

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _loadDrafts();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    await _controller?.dispose();

    _controller = CameraController(
      cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Kamera Hatası: $e');
    }
  }

  void _toggleCamera() {
    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    _initializeCamera();
  }

  Future<void> _loadDrafts() async {
    final savedPhotos = await getIt<DraftPostService>().getDraft(
      widget.event.eventID,
    );
    if (mounted && savedPhotos.isNotEmpty) {
      setState(() => _takenPhotos = List.from(savedPhotos));
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _takenPhotos.length >= 3)
      return;

    try {
      final XFile photo = await _controller!.takePicture();
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: photo.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 70,
        uiSettings: [
          IOSUiSettings(title: 'Düzenle', aspectRatioLockEnabled: true),
        ],
      );

      if (croppedFile != null) {
        setState(() => _takenPhotos.add(File(croppedFile.path)));
        await getIt<DraftPostService>().saveDraft(
          widget.event.id,
          _takenPhotos,
        );
      }
    } catch (e) {
      debugPrint('Fotoğraf hatası: $e');
    }
  }

  void _removePhoto(int index) {
    setState(() => _takenPhotos.removeAt(index));
    getIt<DraftPostService>().saveDraft(widget.event.id, _takenPhotos);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primaryColor;
    const sfPro = 'SF Pro Display';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Üst Alan: Canlı Kamera Önizleme
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_isCameraInitialized &&
                      _controller != null &&
                      _controller!.value.isInitialized)
                    CameraPreview(_controller!)
                  else
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),

                  // Kılavuz Kare
                  Center(
                    child: Container(
                      width: 320.w,
                      height: 320.w,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                  ),

                  // Kapat Butonu
                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),

                  // Kamera Kontrolleri (Flaş, Deklanşör, Çevir)
                  Positioned(
                    bottom: 20.h,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.flash_on, color: Colors.white),
                          onPressed: () {},
                        ),
                        GestureDetector(
                          onTap: _takePhoto,
                          child: Container(
                            width: 75.w,
                            height: 75.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryColor,
                                width: 4.w,
                              ),
                            ),
                            padding: EdgeInsets.all(4.w),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.flip_camera_ios,
                            color: Colors.white,
                          ),
                          onPressed: _toggleCamera,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Alt Alan: Slotlar ve Paylaş
            Container(
              height: 220.h,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Fotoğraf Slotları ve Silme Butonları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final hasPhoto = index < _takenPhotos.length;
                      return Column(
                        children: [
                          Container(
                            width: 85.w,
                            height: 85.w,
                            margin: EdgeInsets.symmetric(horizontal: 6.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.white10),
                              image: hasPhoto
                                  ? DecorationImage(
                                      image: FileImage(_takenPhotos[index]),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                          ),
                          if (hasPhoto)
                            IconButton(
                              onPressed: () => _removePhoto(index),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.white54,
                                size: 20,
                              ),
                            )
                          else
                            const SizedBox(height: 48), // Boşluk koruma
                        ],
                      );
                    }),
                  ),
                  SizedBox(height: 10.h),
                  // Paylaş ve Geri Dön Butonları
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryColor),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'buluşmaya dön',
                            style: TextStyle(
                              fontFamily: sfPro,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_takenPhotos.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NewPostPage(
                                    takenPhotos: _takenPhotos,
                                    event: widget.event,
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'paylaş',
                            style: TextStyle(
                              fontFamily: sfPro,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
