import 'dart:io';
import 'package:bulusalim/screens/bottomnav_screen.dart';
import 'package:bulusalim/screens/camera/new_post_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

// Tasarımdaki özel turuncu renk
const Color kOrangeColor = Color(0xFFF27A5E);

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _takenPhotos = [];

  // --- KAMERA AÇMA ---
  Future<void> _takePhoto() async {
    if (_takenPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("En fazla 3 fotoğraf çekebilirsin!")),
      );
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 80, // Performans için kalite optimizasyonu
      );

      if (photo != null) {
        setState(() {
          _takenPhotos.add(File(photo.path));
        });
      }
    } catch (e) {
      debugPrint("Kamera hatası: $e");
    }
  }

  // --- FOTOĞRAF SİLME ---
  void _removePhoto(int index) {
    setState(() {
      _takenPhotos.removeAt(index);
    });
  }

  // --- SAYFA YÖNLENDİRME ---
  void _navigateToNextPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewPostPage(
          takenPhotos: _takenPhotos,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  borderRadius: BorderRadius.circular(12.r),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // A) Arka Plan / Önizleme
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          image: _takenPhotos.isNotEmpty
                              ? DecorationImage(
                                  image: FileImage(_takenPhotos.last),
                                  fit: BoxFit.cover,
                                  opacity: 0.6,
                                )
                              : null,
                        ),
                        child: _takenPhotos.isEmpty
                            ? Center(
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
                                      "Kamera Önizleme",
                                      style: TextStyle(
                                        color: Colors.white24,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),

                      // B) Kılavuz Çerçevesi
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
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
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
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BottomNavScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      // D) Kontrol Paneli (Deklanşör vb.)
                      Positioned(
                        bottom: 24.h,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.flash_off,
                                  color: Colors.white,
                                  size: 40.sp,
                                ),
                                onPressed: () {},
                              ),
                              GestureDetector(
                                onTap: _takePhoto,
                                child: Container(
                                  width: 80.w,
                                  height: 80.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: kOrangeColor,
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
                              IconButton(
                                icon: Icon(
                                  Icons.flip_camera_ios,
                                  color: Colors.white,
                                  size: 40.sp,
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
              flex: 1,
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
                        final File? imageFile = index < _takenPhotos.length
                            ? _takenPhotos[index]
                            : null;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 94.w,
                              height: 94.w,
                              margin: EdgeInsets.symmetric(horizontal: 8.w),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.grey.shade700,
                                  width: 1,
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
                                top: -10.h,
                                right: 0.w,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    padding: EdgeInsets.all(4.w),
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: Colors.white,
                                      size: 18.sp,
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
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: kOrangeColor,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.r),
                                ),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                "etkinliğe dön",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
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
                                backgroundColor: kOrangeColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.r),
                                ),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                "paylaş",
                                style: TextStyle(
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
