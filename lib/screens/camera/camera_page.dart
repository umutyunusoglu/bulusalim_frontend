import 'dart:io';
import 'package:bulusalim/screens/bottomnav_screen.dart';
import 'package:bulusalim/screens/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();

  // Görselden alınan özel turuncu renk
  final Color _customOrange = const Color(0xFFF27A5E);

  // Çekilen fotoğrafları tutacak liste (Maksimum 3 adet)
  final List<File> _takenPhotos = [];

  // Kamera açma fonksiyonu
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

  // Fotoğraf silme
  void _removePhoto(int index) {
    setState(() {
      _takenPhotos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. BÜYÜK KAMERA ALANI (Kamera + Kontroller + Kapatma) ---
            Expanded(
              flex: 3, // Ekranın büyük kısmını kaplar
              child: Container(
                // Kenar boşlukları
                margin: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 0),
                // Köşeleri yuvarlatılmış Gri Alan
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.r),
                    topRight: Radius.circular(12.r),
                    bottomLeft: Radius.circular(12.r),
                    bottomRight: Radius.circular(12.r),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // A) KAMERA GÖRÜNTÜSÜ / GRİ ZEMİN
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

                      // B) ORTADAKİ KILAVUZ ÇERÇEVESİ
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

                      // C) KAPATMA BUTONU
                      Positioned(
                        top: 16.h,
                        right: 16.w,
                        child: IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28.sp,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          ),
                        ),
                      ),

                      // D) KONTROL ÇUBUĞU
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
                                      color: _customOrange, // Turuncu Çerçeve
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

            // --- 2. ALT PANEL (Galeri Kutuları + Butonlar) ---
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(height: 10.h),
                    // 3 Adet Fotoğraf Kutusu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        File? imageFile = index < _takenPhotos.length
                            ? _takenPhotos[index]
                            : null;

                        return GestureDetector(
                          onTap: () {
                            if (imageFile != null) _removePhoto(index);
                          },
                          child: Container(
                            width: 100.w,
                            height: 100.w,
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
                        );
                      }),
                    ),

                    // --- BUTONLAR ---
                    Row(
                      children: [
                        // Etkinliğe Dön Butonu (Siyah zemin, Turuncu kenarlık)
                        Expanded(
                          child: SizedBox(
                            height: 50.h,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _customOrange, // Turuncu kenarlık
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

                        // Paylaş Butonu (Turuncu zemin - Her zaman aktif)
                        Expanded(
                          child: SizedBox(
                            height: 50.h,
                            child: ElevatedButton(
                              // DÜZELTME: Artık koşulsuz olarak aktif
                              onPressed: () {
                                debugPrint(
                                  "Paylaş butonu tıklandı, ana sayfaya dönülüyor.",
                                );
                                // Ana kısma (HomePage) yönlendirme
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const BottomNavScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _customOrange, // Her zaman turuncu
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
