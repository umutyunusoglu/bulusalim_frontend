import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/draft_post_service.dart';
import 'package:outnest/presentation/camera/view/new_post_page.dart';

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
  int _selectedCameraIndex = 0;

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
      final photo = await _controller!.takePicture();
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: photo.path,
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

    final double sidePadding = 16.w;
    final double topPadding = 110.h;
    final double bottomBlackAreaHeight = 261.h; // Alt siyah panel yüksekliği
    final double screenWidth = MediaQuery.of(context).size.width;
    final double focusSize = screenWidth - (sidePadding * 2);

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
            child: Container(
              width: 75.w,
              height: 75.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor, width: 4.w),
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
    final holeRect = Rect.fromLTWH(sideOffset, topOffset, holeSize, holeSize);
    final holePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(holeRect, Radius.circular(borderRadius)),
      );
    final finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );
    canvas.drawPath(finalPath, Paint()..color = overlayColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
