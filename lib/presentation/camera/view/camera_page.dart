import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/draft_post_service.dart';
import 'package:outnest/presentation/camera/view/new_post_page.dart';
import 'package:volume_controller/volume_controller.dart';

// Ön Kamera Aynalama
Future<String> processFlippedImage(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  final originalImage = img.decodeImage(bytes);

  if (originalImage != null) {
    final flippedImage = img.copyFlip(
      originalImage,
      direction: img.FlipDirection.horizontal,
    );
    final flippedBytes = img.encodeJpg(flippedImage, quality: 80);
    await file.writeAsBytes(flippedBytes);
  }
  return path;
}

class CameraPage extends StatefulWidget {
  const CameraPage({required this.event, super.key});

  final EventEntity event;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<File> _takenPhotos = [];
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;
  bool _isProcessing = false;

  // Ses tuşu sabitleme
  double _initialVolume = 0.5;
  bool _isRestoringVolume = false;

  bool get _isFrontCamera =>
      _controller?.description.lensDirection == CameraLensDirection.front;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeCamera();
    _loadDrafts();
    _setupVolumeListener();
  }

  Future<void> _setupVolumeListener() async {
    _initialVolume = await VolumeController.instance.getVolume();
    VolumeController.instance.showSystemUI = false;

    VolumeController.instance.addListener((volume) async {
      if (!mounted ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }

      if (_isRestoringVolume) {
        _isRestoringVolume = false;
        return;
      }

      _isRestoringVolume = true;
      await VolumeController.instance.setVolume(_initialVolume);

      if (!_isProcessing) {
        await _takePhoto();
      }
    });
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final oldController = _controller;
    if (mounted) setState(() => _isCameraInitialized = false);

    // Eski kamerayı güvenlice arka planda kapat
    await oldController?.dispose();

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
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Kamera Hatası: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (_isProcessing) return;

    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    await _initializeCamera();
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
    if (!mounted ||
        _controller == null ||
        !_controller!.value.isInitialized ||
        _takenPhotos.length >= 3 ||
        _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final photo = await _controller!.takePicture();
      var currentPhotoPath = photo.path;

      if (_isFrontCamera) {
        currentPhotoPath = await compute(processFlippedImage, currentPhotoPath);
      }

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: currentPhotoPath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 80,
        uiSettings: [
          IOSUiSettings(
            title: 'Kırp',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
          AndroidUiSettings(
            toolbarTitle: 'Kırp',
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        setState(() => _takenPhotos.add(File(croppedFile.path)));
        await getIt<DraftPostService>().saveDraft(
          widget.event.id,
          _takenPhotos,
        );
      }
    } catch (e) {
      debugPrint('Fotoğraf çekim hatası: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _removePhoto(int index) {
    if (_isProcessing) return;

    setState(() => _takenPhotos.removeAt(index));
    getIt<DraftPostService>().saveDraft(widget.event.id, _takenPhotos);
  }

  @override
  void dispose() {
    VolumeController.instance.removeListener();
    VolumeController.instance.showSystemUI = true;
    WidgetsBinding.instance.removeObserver(this);

    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primaryColor;
    const sfPro = 'SF Pro Display';

    final sidePadding = 16.w;
    final topPadding = 110.h;
    final bottomBlackAreaHeight = 261.h;
    final focusSize = MediaQuery.of(context).size.width - (sidePadding * 2);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. KATMAN: KAMERA ÖNİZLEME
          if (_isCameraInitialized && _controller != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: bottomBlackAreaHeight,
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.previewSize!.height,
                    height: _controller!.value.previewSize!.width,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
            ),

          // 2. KATMAN: SAYDAM OVERLAY (Kamera üzerindeki maske)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: bottomBlackAreaHeight,
            child: IgnorePointer(
              child: CustomPaint(
                painter: HoleOverlayPainter(
                  holeSize: focusSize,
                  topOffset: topPadding,
                  sideOffset: sidePadding,
                  borderRadius: 20.r,
                  overlayColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ),

          // 3. KATMAN: UI ELEMANLARI
          SafeArea(
            child: Stack(
              children: [
                // Üst Kapat Butonu
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => context.push('/home'),
                  ),
                ),

                // Beyaz Çerçeve
                Positioned(
                  top: topPadding - MediaQuery.of(context).padding.top,
                  left: sidePadding,
                  child: IgnorePointer(
                    child: Container(
                      width: focusSize,
                      height: focusSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 2.w,
                        ),
                      ),
                    ),
                  ),
                ),

                // KAMERA BUTONLARI (SAYDAM KISIMDA - Siyah panelin hemen üstünde)
                Positioned(
                  bottom: bottomBlackAreaHeight + 10.h,
                  left: 0,
                  right: 0,
                  child: _buildActionButtons(primaryColor),
                ),

                // ALT SİYAH PANEL (Sadece Slotlar ve Alt Butonlar)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: bottomBlackAreaHeight,
                    width: double.infinity,
                    color: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPhotoSlots(),
                        _buildBottomActionButtons(primaryColor, sfPro),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color primaryColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: _takePhoto,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 15),
              width: 75.w,
              height: 75.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isProcessing ? Colors.grey : primaryColor,
                  width: 4.w,
                ),
              ),
              padding: EdgeInsets.all(4.w),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _isProcessing ? Colors.grey.shade400 : Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: _toggleCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final hasPhoto = index < _takenPhotos.length;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Column(
            children: [
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.white24),
                  image: hasPhoto
                      ? DecorationImage(
                          image: FileImage(_takenPhotos[index]),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              if (hasPhoto)
                GestureDetector(
                  onTap: () => _removePhoto(index),
                  child: Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white54,
                      size: 24,
                    ),
                  ),
                )
              else
                SizedBox(height: 24.h),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBottomActionButtons(Color primaryColor, String sfPro) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.go('/home'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: const StadiumBorder(),
              ),
              child: Text(
                'buluşmaya dön',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
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
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: const StadiumBorder(),
              ),
              child: Text(
                'paylaş',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HoleOverlayPainter extends CustomPainter {
  final double holeSize;
  final double topOffset;
  final double sideOffset;
  final double borderRadius;
  final Color overlayColor;

  HoleOverlayPainter({
    required this.holeSize,
    required this.topOffset,
    required this.sideOffset,
    required this.borderRadius,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(sideOffset, topOffset, holeSize, holeSize),
          Radius.circular(borderRadius),
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, backgroundPath, holePath),
      Paint()..color = overlayColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
