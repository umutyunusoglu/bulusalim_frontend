import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/services/draft_post_service.dart';
import 'package:outnest/screens/camera/new_post_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart'; // YENİ: GoRouter eklendi
import 'package:image_picker/image_picker.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({required this.event, super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
  final EventEntity event;
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();
  List<File> _takenPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadDrafts(); // Sayfa açılınca eski fotoları yükle
  }

  Future<void> _loadDrafts() async {
    // Servisten veriyi çek
    // NOT: event entity'nizde 'id' alanı olduğunu varsayıyorum (widget.event.id)
    final savedPhotos = await getIt<DraftPostService>().getDraft(
      widget.event.eventID,
    );

    // Eğer sayfa hala açıksa ve kayıtlı foto varsa listeyi güncelle
    if (mounted && savedPhotos.isNotEmpty) {
      setState(() {
        _takenPhotos = List.from(savedPhotos);
      });
    }
  }

  Future<void> _updateDraft() async {
    await getIt<DraftPostService>().saveDraft(widget.event.id, _takenPhotos);
  }

  Future<void> _takePhoto() async {
    if (_takenPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En fazla 3 fotoğraf çekebilirsin!')),
      );
      return;
    }

    try {
      // 1. Fotoğrafı Çek
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100, // Kırpma yapacağımız için önce yüksek kalite alalım
      );

      if (photo != null) {
        // 2. Fotoğrafı Kare (1:1) Kırp
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: photo.path,
          aspectRatio: const CropAspectRatio(
            ratioX: 1,
            ratioY: 1,
          ), // KARE ZORLAMASI
          compressQuality:
              70, // Sıkıştırmayı burada yapıyoruz (700KB -> ~150KB)
          maxWidth: 1080, // Sosyal medya standardı (Genişlik)
          maxHeight: 1080, // Sosyal medya standardı (Yükseklik)
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Fotoğrafı Düzenle',
              toolbarColor: AppColors.primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true, // Kullanıcı oranı değiştiremesin
            ),
            IOSUiSettings(
              title: 'Fotoğrafı Düzenle',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _takenPhotos.add(File(croppedFile.path));
          });
          await _updateDraft();
        }
      }
    } on Exception catch (e) {
      debugPrint('Kamera veya Kırpma hatası: $e');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _takenPhotos.removeAt(index);
    });
    _updateDraft();
  }

  void _navigateToNextPage() {
    if (_takenPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir fotoğraf çekin!')),
      );
      return;
    }

    // NewPostPage veri (dosya listesi) istediği için burayı standart push ile bırakıyoruz.
    // GoRouter ile dosya taşımak için ekstra router ayarı gerekir, bu yöntem daha pratiktir.
    Navigator.push(
      context,
      MaterialPageRoute<NewPostPage>(
        builder: (context) =>
            NewPostPage(takenPhotos: _takenPhotos, event: widget.event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primaryColor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ----------------------------------------------------------
            // 1. ÜST ALAN: KAMERA ÖNİZLEME + KONTROLLER
            // ----------------------------------------------------------
            Expanded(
              flex: 3,
              child: Container(
                margin: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // A) Arka Plan / Önizleme Placeholder
                      ColoredBox(
                        color: const Color(0xFF1A1A1A), // Koyu Gri
                        child: _takenPhotos.isNotEmpty
                            ? Image.file(
                                _takenPhotos.last,
                                fit: BoxFit.cover,
                                opacity: const AlwaysStoppedAnimation(0.6),
                              )
                            : Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      color: Colors.white24,
                                      size: 50.sp,
                                    ),
                                    SizedBox(height: 10.h),
                                    Text(
                                      'Kamera Önizleme',
                                      style: TextStyle(
                                        fontFamily: 'Urbanist',
                                        color: Colors.white24,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      // B) Kılavuz Çerçevesi (Guide)
                      Positioned(
                        top: 60.h,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 341.w,
                            height: 371.h,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                        ),
                      ),

                      // C) Kapatma Butonu
                      Positioned(
                        top: 16.h,
                        right: 16.w,
                        child: IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28.sp,
                          ),
                          onPressed: () {
                            // ESKİ KOD (HATA VEREN):
                            /*
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BottomNavScreen(),
                              ),
                            );
                            */

                            // YENİ KOD:
                            // Kamera sayfasını kapatıp geldiğimiz yere (Home) dönüyoruz.
                            context.pop();
                          },
                        ),
                      ),

                      // D) Kontrol Paneli
                      Positioned(
                        bottom: 24.h,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Flaş
                              IconButton(
                                icon: Icon(
                                  Icons.flash_off,
                                  color: Colors.white,
                                  size: 32.sp,
                                ),
                                onPressed: () {},
                              ),

                              // Deklanşör
                              GestureDetector(
                                onTap: _takePhoto,
                                child: Container(
                                  width: 80.w,
                                  height: 80.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: primaryColor,
                                      width: 4.w,
                                    ),
                                  ),
                                  padding: EdgeInsets.all(4.w),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),

                              // Kamera Çevir
                              IconButton(
                                icon: Icon(
                                  Icons.flip_camera_ios,
                                  color: Colors.white,
                                  size: 32.sp,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ----------------------------------------------------------
            // 2. ALT ALAN: GALERİ + AKSİYON BUTONLARI
            // ----------------------------------------------------------
            Expanded(
              child: Container(
                color: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(height: 10.h),

                    // Fotoğraf Listesi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final imageFile = index < _takenPhotos.length
                            ? _takenPhotos[index]
                            : null;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 94.w,
                              height: 94.w,
                              margin: EdgeInsets.symmetric(horizontal: 6.w),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.grey.shade800,
                                ),
                                image: imageFile != null
                                    ? DecorationImage(
                                        image: FileImage(imageFile),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                            ),
                            if (imageFile != null)
                              Positioned(
                                top: -8.h,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    padding: EdgeInsets.all(4.w),
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: 16.sp,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                    ),

                    // Butonlar
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50.h,
                            child: OutlinedButton(
                              // YENİ: Etkinliğe dön (Geri çık)
                              onPressed: () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: primaryColor,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.r),
                                ),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                'etkinliğe dön',
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: SizedBox(
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: _navigateToNextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.r),
                                ),
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              child: Text(
                                'paylaş',
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
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
          ],
        ),
      ),
    );
  }
}
