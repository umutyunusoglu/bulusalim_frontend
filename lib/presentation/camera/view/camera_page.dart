import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/draft_post_service.dart';
import 'package:outnest/presentation/camera/controllers/image_cropper.dart';
import 'package:outnest/presentation/camera/view/new_post_page.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart'; // Popuplar için eklendi
import 'package:volume_controller/volume_controller.dart';

// --- Yardımcı Metodlar ---
Future<String> processFlippedImage(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  final originalImage = img.decodeImage(bytes);

  if (originalImage != null) {
    // Ön kamera için resmi yatay eksende (ayna) çevirir
    final flippedImage = img.copyFlip(
      originalImage,
      direction: img.FlipDirection.horizontal,
    );
    final flippedBytes = img.encodeJpg(flippedImage, quality: 80);
    await file.writeAsBytes(flippedBytes);
  }
  return path;
}

// --- Sayfa Durumları ---
enum CameraState { camera, preview, gallery }

class CameraPage extends HookWidget {
  const CameraPage({required this.event, super.key});

  final EventEntity event;

  @override
  Widget build(BuildContext context) {
    final isMounted = useIsMounted();
    final currentState = useState<CameraState>(CameraState.camera);
    final takenPhotos = useState<List<File>>([]);
    final currentPreviewFile = useState<File?>(null);
    final isCameraInitialized = useState(false);
    final selectedCameraIndex = useState(0);
    final isProcessing = useState(false);

    final controllerRef = useRef<CameraController?>(null);
    final initialVolume = useRef<double>(0.5);
    final isRestoringVolume = useRef(false);

    // Her initializeCamera çağrısına unique token verir.
    final initToken = useRef<int>(0);

    // GALERİ İÇİN PageController ve Durumlar
    final pageController = usePageController(viewportFraction: 0.86);
    final isDragging = useState(false);
    final lastAutoScrollTime = useRef<DateTime>(DateTime.now());

    final screenWidth = MediaQuery.of(context).size.width;

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

      if (initToken.value != myToken || !isMounted()) {
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

        final isFrontCamera =
            controller.description.lensDirection == CameraLensDirection.front;

        if (isFrontCamera) {
          currentPhotoPath = await processFlippedImage(currentPhotoPath);
        }

        final croppedFile = await cropImage(currentPhotoPath);

        if (croppedFile != null) {
          currentPreviewFile.value = File(croppedFile.path);
          currentState.value = CameraState.preview;
        }
      } catch (e) {
        debugPrint('Fotoğraf çekim hatası: $e');
      } finally {
        isProcessing.value = false;
      }
    }

    // ── Önizleme Onay/İptal ──────────────────────────────────────────────────
    void confirmPreview() {
      if (currentPreviewFile.value != null && takenPhotos.value.length < 3) {
        final updatedPhotos = [...takenPhotos.value, currentPreviewFile.value!];
        takenPhotos.value = updatedPhotos;
        getIt<DraftPostService>().saveDraft(event.id, updatedPhotos);
      }
      currentPreviewFile.value = null;
      currentState.value = CameraState.camera;
    }

    void discardPreview() {
      currentPreviewFile.value = null;
      currentState.value = CameraState.camera;
    }

    // ── Galeriden Silme ──────────────────────────────────────────────────────
    void deleteFromGallery(int index) {
      if (index >= takenPhotos.value.length) return;

      final updatedPhotos = [...takenPhotos.value]..removeAt(index);
      takenPhotos.value = updatedPhotos;
      getIt<DraftPostService>().saveDraft(event.id, updatedPhotos);

      if (updatedPhotos.isEmpty) {
        currentState.value = CameraState.camera;
      }
    }

    // ── Sürüklerken Otomatik Ekran Kaydırma ──────────────────────────────────
    void handleAutoScroll(DragUpdateDetails details) {
      if (!pageController.hasClients) return;

      final now = DateTime.now();
      if (now.difference(lastAutoScrollTime.value).inMilliseconds < 400) return;

      final dx = details.globalPosition.dx;
      final currentPageIndex = pageController.page?.round() ?? 0;

      if (dx > screenWidth * 0.85) {
        if (currentPageIndex < takenPhotos.value.length - 1) {
          lastAutoScrollTime.value = now;
          pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else if (dx < screenWidth * 0.15) {
        if (currentPageIndex > 0) {
          lastAutoScrollTime.value = now;
          pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    }

    // ── Effects ──────────────────────────────────────────────────────────────
    useEffect(() {
      initializeCamera();
      return () {
        initToken.value++;
        final controller = controllerRef.value;
        controllerRef.value = null;
        isCameraInitialized.value = false;
        controller?.dispose();
      };
    }, const []);

    // ── Effect: Volume listener ──────────────────────────────────────────────
    useEffect(() {
      int skipInitialEvents = 2;

      Future<void> setupVolumeListener() async {
        try {
          initialVolume.value = await VolumeController.instance.getVolume();
          VolumeController.instance.showSystemUI = false;

          VolumeController.instance.addListener((volume) async {
            if (skipInitialEvents > 0) {
              skipInitialEvents--;
              return;
            }

            if (isRestoringVolume.value) {
              isRestoringVolume.value = false;
              return;
            }

            isRestoringVolume.value = true;
            await VolumeController.instance.setVolume(initialVolume.value);

            if (currentState.value == CameraState.camera &&
                !isProcessing.value) {
              await takePhoto();
            }
          });
        } catch (e) {
          debugPrint('Ses dinleyicisi başlatılamadı: $e');
        }
      }

      setupVolumeListener();

      return () {
        VolumeController.instance.removeListener();
        VolumeController.instance.showSystemUI = true;
      };
    }, [currentState.value, isProcessing.value]);

    // ── Effect: Draft yükleme ────────────────────────────────────────────────
    useEffect(() {
      getIt<DraftPostService>().getDraft(event.eventID).then((savedPhotos) {
        if (savedPhotos.isNotEmpty) {
          takenPhotos.value = List.from(savedPhotos);
        }
      });
      return null;
    }, const []);

    // ── Tasarım Koordinatları ────────────────────────────────────────────────
    final topPadding = 60.h;
    final iconHeight = 24.h;
    final gapBelowIcons = 47.h;
    final rectHeight = 481.h;
    final galleryRectHeight = 452.h;
    final bottomPadding = 89.h;
    final sidePadding = 16.w;
    final rectWidth = screenWidth - (sidePadding * 2);
    final topOffset = topPadding + iconHeight + gapBelowIcons;

    // ── Build ────────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // MOD 1: KAMERA
          if (currentState.value == CameraState.camera) ...[
            Positioned.fill(
              child: isCameraInitialized.value && controllerRef.value != null
                  ? ClipRect(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controllerRef.value!.value.previewSize!.height,
                          height: controllerRef.value!.value.previewSize!.width,
                          child: CameraPreview(controllerRef.value!),
                        ),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CameraOverlayPainter(
                    clearRect: Rect.fromLTWH(
                      sidePadding,
                      topOffset,
                      rectWidth,
                      rectHeight,
                    ),
                    overlayColor: Colors.black.withOpacity(0.45),
                    borderRadius: 24.r,
                  ),
                ),
              ),
            ),

            Positioned(
              top: topPadding,
              left: sidePadding,
              right: sidePadding,
              child: SizedBox(
                height: iconHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Symbols.reply,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    Stack(
                      alignment: Alignment.topRight,
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Symbols.photo_library,
                            color: takenPhotos.value.isNotEmpty
                                ? Colors.white
                                : Colors.white54,
                            size: 24,
                          ),
                          onPressed: takenPhotos.value.isNotEmpty
                              ? () {
                                  currentState.value = CameraState.gallery;
                                }
                              : null,
                        ),
                        if (takenPhotos.value.isNotEmpty)
                          Positioned(
                            top: -5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${takenPhotos.value.length}',
                                style: TextStyle(
                                  fontSize: 8.sp,
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
            ),

            Positioned(
              bottom: bottomPadding,
              left: 0,
              right: 0,
              child: _ActionButtons(
                primaryColor: AppColors.primaryColor,
                isProcessing: isProcessing.value,
                onTakePhoto: takePhoto,
                onToggleCamera: toggleCamera,
                isMaxPhotosReached: takenPhotos.value.length >= 3,
              ),
            ),
          ],

          // MOD 2: ÖNİZLEME (Onay Ekranı)
          if (currentState.value == CameraState.preview &&
              currentPreviewFile.value != null) ...[
            Container(color: const Color(0xFF1A1A1A)),

            Positioned(
              top: topPadding,
              left: sidePadding,
              right: sidePadding,
              child: SizedBox(
                height: iconHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Symbols.reply,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: discardPreview,
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Symbols.photo_library,
                        color: Colors.white54,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: topOffset,
              left: sidePadding,
              right: sidePadding,
              child: Container(
                width: rectWidth,
                height: rectHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.r),
                  image: DecorationImage(
                    image: FileImage(currentPreviewFile.value!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: bottomPadding,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 72.w,
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: 40.w,
                          ),
                          child: GestureDetector(
                            onTap: discardPreview,
                            child: const Icon(
                              Symbols.delete,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: confirmPreview,
                      child: const Center(
                        child: Icon(
                          Symbols.check_circle,
                          color: Colors.white,
                          size: 72,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // MOD 3: GALERİ (Drag & Drop)
          if (currentState.value == CameraState.gallery &&
              takenPhotos.value.isNotEmpty) ...[
            Container(color: const Color(0xFF1A1A1A)),

            Positioned(
              top: topPadding,
              left: sidePadding,
              right: sidePadding,
              child: SizedBox(
                height: iconHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => currentState.value = CameraState.camera,
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewPostPage(
                              takenPhotos: takenPhotos.value,
                              event: event,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: topOffset,
              left: 0,
              right: 0,
              child: SizedBox(
                height: galleryRectHeight,
                child: PageView.builder(
                  controller: pageController,
                  physics: isDragging.value
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  itemCount: takenPhotos.value.length,
                  itemBuilder: (context, index) {
                    final photo = takenPhotos.value[index];

                    return DragTarget<int>(
                      onWillAcceptWithDetails: (details) =>
                          details.data != index,
                      onAcceptWithDetails: (details) {
                        final oldIndex = details.data;
                        final photos = List<File>.from(takenPhotos.value);
                        final item = photos.removeAt(oldIndex);
                        photos.insert(index, item);
                        takenPhotos.value = photos;
                        getIt<DraftPostService>().saveDraft(event.id, photos);

                        pageController.jumpToPage(index);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isTarget = candidateData.isNotEmpty;

                        return LongPressDraggable<int>(
                          data: index,
                          delay: const Duration(milliseconds: 150),
                          onDragStarted: () => isDragging.value = true,
                          onDragEnd: (_) => isDragging.value = false,
                          onDragCompleted: () => isDragging.value = false,
                          onDraggableCanceled: (_, __) =>
                              isDragging.value = false,
                          onDragUpdate: handleAutoScroll,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Opacity(
                              opacity: 0.75,
                              child: Transform.scale(
                                scale: 1.04,
                                child: Container(
                                  width: screenWidth * 0.86,
                                  height: galleryRectHeight,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 20,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                    image: DecorationImage(
                                      image: FileImage(photo),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.0,
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 11.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                            ),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.symmetric(horizontal: 11.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24.r),
                              border: isTarget
                                  ? Border.all(
                                      color: AppColors.primaryColor,
                                      width: 4.w,
                                    )
                                  : null,
                              image: DecorationImage(
                                image: FileImage(photo),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: isTarget
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            Positioned(
              top: topOffset + galleryRectHeight + 16.h,
              left: 0,
              right: 0,
              child: HookBuilder(
                builder: (context) {
                  useListenable(pageController);
                  final currentPage = pageController.hasClients
                      ? (pageController.page?.round() ?? 0)
                      : 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      takenPhotos.value.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentPage == index
                              ? Colors.white
                              : Colors.white38,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ==========================================
            // GALERİ İNDİRME VE SİLME BUTONLARI
            // ==========================================
            Positioned(
              bottom: 130,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 110.w),

                  GestureDetector(
                    onTap: () {
                      final currentIndex = pageController.page?.round() ?? 0;
                      deleteFromGallery(currentIndex);
                    },
                    child: SizedBox(
                      width: 40.w,
                      height: 40.w,
                      child: const Center(
                        child: Icon(
                          Symbols.delete,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 89.w),

                  // İNDİRME İŞLEMİ EKLENDİ
                  GestureDetector(
                    onTap: () async {
                      final currentIndex = pageController.page?.round() ?? 0;
                      if (currentIndex >= 0 &&
                          currentIndex < takenPhotos.value.length) {
                        final fileToSave = takenPhotos.value[currentIndex];
                        try {
                          // Resmi galeriye kaydet
                          final result = await ImageGallerySaver.saveFile(
                            fileToSave.path,
                          );

                          if (result['isSuccess'] == true && context.mounted) {
                            showInfoPopup(
                              context,
                              message: 'Fotoğraf galeriye kaydedildi!',
                            );
                          } else if (context.mounted) {
                            showErrorPopup(
                              context,
                              message: 'Fotoğraf kaydedilemedi.',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showErrorPopup(
                              context,
                              message: 'Bir hata oluştu: $e',
                            );
                          }
                        }
                      }
                    },
                    child: SizedBox(
                      width: 40.w,
                      height: 40.w,
                      child: const Center(
                        child: Icon(
                          Symbols.download,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 110.w),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Kamera Aksiyon Butonları
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.primaryColor,
    required this.isProcessing,
    required this.onTakePhoto,
    required this.onToggleCamera,
    required this.isMaxPhotosReached,
  });

  final Color primaryColor;
  final bool isProcessing;
  final VoidCallback onTakePhoto;
  final VoidCallback onToggleCamera;
  final bool isMaxPhotosReached;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.bolt, color: Colors.white, size: 32),
            onPressed: () {},
          ),

          GestureDetector(
            onTap: isMaxPhotosReached ? null : onTakePhoto,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 76.w,
              height: 76.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isProcessing || isMaxPhotosReached
                      ? Colors.grey
                      : primaryColor,
                  width: 4.w,
                ),
              ),
              padding: EdgeInsets.all(4.w),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isProcessing || isMaxPhotosReached
                      ? Colors.grey.shade600
                      : Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white, size: 30),
            onPressed: onToggleCamera,
          ),
        ],
      ),
    );
  }
}

// Kamera Overlay
class CameraOverlayPainter extends CustomPainter {
  CameraOverlayPainter({
    required this.clearRect,
    required this.overlayColor,
    required this.borderRadius,
  });
  final Rect clearRect;
  final Color overlayColor;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;
    final fullScreenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final clearPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(clearRect, Radius.circular(borderRadius)),
      );
    final finalPath = Path.combine(
      PathOperation.difference,
      fullScreenPath,
      clearPath,
    );
    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(covariant CameraOverlayPainter oldDelegate) {
    return oldDelegate.clearRect != clearRect ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.borderRadius != borderRadius;
  }
}
