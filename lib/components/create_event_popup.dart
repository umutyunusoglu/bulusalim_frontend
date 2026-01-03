import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateEventPopup extends StatefulWidget {
  const CreateEventPopup({
    required this.categories,
    required this.onClose,
    required this.onNext,
    super.key,
  });

  final Map<String, String> categories;
  final VoidCallback onClose;
  final ValueChanged<String> onNext;

  @override
  State<CreateEventPopup> createState() => _CreateEventPopupState();
}

class _CreateEventPopupState extends State<CreateEventPopup> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Tasarımdaki boyutlar
      width: 361.w,
      height: 447.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. HEADER (Geri Butonu ve Başlık)
          Stack(
            alignment: Alignment.center,
            children: [
              // Sol: Geri Butonu
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Icon(
                    Icons.undo,
                    size: 24.sp,
                    color: Colors.black,
                  ), // Tasarımdaki kavisli ok
                ),
              ),
              // Orta: Başlık
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label_outline, size: 20.sp, color: Colors.black),
                  SizedBox(width: 8.w),
                  Text(
                    "Buluşma Teması",
                    style: TextStyle(
                      fontFamily: 'Urbanist', // veya SF Pro
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // 2. KATEGORİ LİSTESİ (Scrollable Wrap)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
                spacing: 12.w, // Yatay boşluk
                runSpacing: 12.h, // Dikey boşluk
                alignment: WrapAlignment.center,
                children: widget.categories.entries.map((entry) {
                  final category = entry.key;
                  final emoji = entry.value;
                  final isSelected = _selectedCategory == category;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        // Seçiliyse turuncu çerçeve, değilse gri dolgu
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12.r),
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFFFFCCBC),
                                width: 1.5,
                              )
                            : Border.all(color: Colors.transparent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: TextStyle(fontSize: 14.sp)),
                          SizedBox(width: 6.w),
                          Text(
                            category
                                .toLowerCase(), // Tasarımda hepsi küçük harf gibi duruyor
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // 3. İLERLE BUTONU
          SizedBox(
            width: 160.w, // Buton genişliği (Göz kararı ortalama)
            height: 48.h,
            child: ElevatedButton(
              onPressed: _selectedCategory == null
                  ? null // Kategori seçilmediyse pasif
                  : () {
                      widget.onNext(_selectedCategory!);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFFFFCCBC,
                ), // Tasarımdaki pastel turuncu
                foregroundColor: const Color(
                  0xFFBF360C,
                ), // Yazı rengi (Koyu turuncu)
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
              child: Text(
                "İlerle",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
