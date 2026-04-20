import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/draft_post_service.dart';
import 'package:outnest/presentation/camera/controllers/image_cropper.dart';
import 'package:outnest/presentation/camera/view/components/hole_overlay_painter.dart';
import 'package:outnest/presentation/camera/view/new_post_page.dart';
import 'package:volume_controller/volume_controller.dart';

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

class CameraPage extends HookWidget {
  const CameraPage({required this.event, super.key});

  final EventEntity event;

  @override
  Widget build(BuildContext context) {
    final takenPhotos = useState<List<File>>([]);
    final isCameraInitialized = useState(false);
    final selectedCameraIndex = useState(0);
    final isProcessing = useState(false);

    final controllerRef = useRef<CameraController?>(null);
    final initialVolume = useRef<double>(0.5);
    final isRestoringVolume = useRef(false);

    // Her initializeCamera çağrısına unique token verir.
    // Async işlem biterken token değişmişse o init iptal sayılır.
    final initToken = useRef<int>(0);

    final isFrontCamera =
        controllerRef.value?.description.lensDirection ==
        CameraLensDirection.front;

    // ── Kamera başlatma ──────────────────────────────────────────────────────
    Future<void> initializeCamera() async {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final myToken = ++initToken.value;

      final oldController = controllerRef.value;
      controllerRef.value = null;
      isCameraInitialized.value = false;

      try {
        await oldController?.dispose();
      } catch (_) {}

      if (initToken.value != myToken) return;

      final newController = CameraController(
        cameras[selectedCameraIndex.value],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.jpeg,
      );

      try {
        await newController.initialize();
        await newController.lockCaptureOrientation(
          DeviceOrientation.portraitUp,
        );
      } catch (e) {
        debugPrint('Kamera Hatası: $e');
        try {
          await newController.dispose();
        } catch (_) {}
        return;
      }

      if (initToken.value != myToken) {
        try {
          await newController.dispose();
        } catch (_) {}
        return;
      }

      controllerRef.value = newController;
      isCameraInitialized.value = true;
    }

    // ── Kamera geçişi ────────────────────────────────────────────────────────
    Future<void> toggleCamera() async {
      if (isProcessing.value) return;
      selectedCameraIndex.value = selectedCameraIndex.value == 0 ? 1 : 0;
      await initializeCamera();
    }

    // ── Fotoğraf çekme ───────────────────────────────────────────────────────
    Future<void> takePhoto() async {
      final controller = controllerRef.value;

      if (controller == null ||
          !controller.value.isInitialized ||
          takenPhotos.value.length >= 3 ||
          isProcessing.value) {
        return;
      }

      isProcessing.value = true;

      try {
        final photo = await controller.takePicture();
        var currentPhotoPath = photo.path;

        if (isFrontCamera) {
          currentPhotoPath = await processFlippedImage(currentPhotoPath);
        }

        final croppedFile = await cropImage(currentPhotoPath);

        if (croppedFile != null) {
          takenPhotos.value = [...takenPhotos.value, File(croppedFile.path)];
          await getIt<DraftPostService>().saveDraft(
            event.id,
            takenPhotos.value,
          );
        }
      } catch (e) {
        debugPrint('Fotoğraf çekim hatası: $e');
      } finally {
        isProcessing.value = false;
      }
    }

    // ── Effect: İlk kamera açılışı — sadece mount/unmount ───────────────────
    useEffect(() {
      initializeCamera();
      return () {
        initToken.value++; // devam eden init'leri iptal et
        final controller = controllerRef.value;
        controllerRef.value = null;
        isCameraInitialized.value = false;
        controller?.dispose();
      };
    }, const []);

    // ── Effect: Volume listener ──────────────────────────────────────────────
    useEffect(() {
      Future<void> setup() async {
        initialVolume.value = await VolumeController.instance.getVolume();
        VolumeController.instance.showSystemUI = false;

        VolumeController.instance.addListener((volume) async {
          if (isRestoringVolume.value) {
            isRestoringVolume.value = false;
            return;
          }

          isRestoringVolume.value = true;
          await VolumeController.instance.setVolume(initialVolume.value);

          if (!isProcessing.value) {
            await takePhoto();
          }
        });
      }

      setup();

      return () {
        VolumeController.instance.removeListener();
        VolumeController.instance.showSystemUI = true;
      };
    }, const []);

    // ── Effect: Draft yükleme ────────────────────────────────────────────────
    useEffect(() {
      getIt<DraftPostService>().getDraft(event.eventID).then((savedPhotos) {
        if (savedPhotos.isNotEmpty) {
          takenPhotos.value = List.from(savedPhotos);
        }
      });
      return null;
    }, const []);

    // ── Layout sabitleri ─────────────────────────────────────────────────────
    const primaryColor = AppColors.primaryColor;
    const sfPro = 'SF Pro Display';

    final sidePadding = 16.w;
    final topPadding = 110.h;
    final bottomBlackAreaHeight = 261.h;
    final focusSize = MediaQuery.of(context).size.width - (sidePadding * 2);

    // ── Build ────────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. KATMAN: KAMERA ÖNİZLEME
          if (isCameraInitialized.value && controllerRef.value != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: bottomBlackAreaHeight,
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controllerRef.value!.value.previewSize!.height,
                    height: controllerRef.value!.value.previewSize!.width,
                    child: CameraPreview(controllerRef.value!),
                  ),
                ),
              ),
            ),

          // 2. KATMAN: SAYDAM OVERLAY
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

                // Kamera Butonları
                Positioned(
                  bottom: bottomBlackAreaHeight + 10.h,
                  left: 0,
                  right: 0,
                  child: _ActionButtons(
                    primaryColor: primaryColor,
                    isProcessing: isProcessing.value,
                    onTakePhoto: takePhoto,
                    onToggleCamera: toggleCamera,
                  ),
                ),

                // Alt Siyah Panel
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
                        _PhotoSlots(
                          photos: takenPhotos.value,
                          onRemove: (index) {
                            if (!isProcessing.value) {
                              final updated = [...takenPhotos.value]
                                ..removeAt(index);
                              takenPhotos.value = updated;
                              getIt<DraftPostService>().saveDraft(
                                event.id,
                                updated,
                              );
                            }
                          },
                        ),
                        _BottomActionButtons(
                          primaryColor: primaryColor,
                          sfPro: sfPro,
                          hasPhotos: takenPhotos.value.isNotEmpty,
                          onReturn: () => context.go('/home'),
                          onShare: () {
                            if (takenPhotos.value.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NewPostPage(
                                    takenPhotos: takenPhotos.value,
                                    event: event,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
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
}

// ---------------------------------------------------------------------------
// Alt Widget'lar
// ---------------------------------------------------------------------------

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.primaryColor,
    required this.isProcessing,
    required this.onTakePhoto,
    required this.onToggleCamera,
  });

  final Color primaryColor;
  final bool isProcessing;
  final VoidCallback onTakePhoto;
  final VoidCallback onToggleCamera;

  @override
  Widget build(BuildContext context) {
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
            onTap: onTakePhoto,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 75.w,
              height: 75.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isProcessing ? Colors.grey : primaryColor,
                  width: 4.w,
                ),
              ),
              padding: EdgeInsets.all(4.w),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isProcessing ? Colors.grey.shade400 : Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: onToggleCamera,
          ),
        ],
      ),
    );
  }
}

class _PhotoSlots extends StatelessWidget {
  const _PhotoSlots({required this.photos, required this.onRemove});

  final List<File> photos;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final hasPhoto = index < photos.length;
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
                          image: FileImage(photos[index]),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              if (hasPhoto)
                GestureDetector(
                  onTap: () => onRemove(index),
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
}

class _BottomActionButtons extends StatelessWidget {
  const _BottomActionButtons({
    required this.primaryColor,
    required this.sfPro,
    required this.hasPhotos,
    required this.onReturn,
    required this.onShare,
  });

  final Color primaryColor;
  final String sfPro;
  final bool hasPhotos;
  final VoidCallback onReturn;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onReturn,
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
                  fontFamily: sfPro,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: ElevatedButton(
              onPressed: hasPhotos ? onShare : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                disabledBackgroundColor: primaryColor.withOpacity(0.4),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: const StadiumBorder(),
              ),
              child: Text(
                'paylaş',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: sfPro,
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
