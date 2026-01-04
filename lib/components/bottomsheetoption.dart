import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BottomSheetOption {
  // Eğer true ise  kırmızı olur.

  BottomSheetOption({
    required this.icon,
    required this.text,
    required this.onTap,
    this.isDestructive = false,
  });
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isDestructive;
}

class CustomActionBottomSheet extends StatelessWidget {
  const CustomActionBottomSheet({
    required this.options,
    this.height, //yukekliği dışarıdan ezebilir
    super.key,
  });

  final List<BottomSheetOption> options;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final baseTextStyle = TextStyle(
      fontFamily: 'SF Pro Display',
      fontWeight: FontWeight.w400,
      fontSize: 14.sp,
      height: 1,
      letterSpacing: 0,
      color: Colors.black87,
    );

    return Container(
      // Eğer yükseklik verilmezse içeriğe göre esner, verilirse sabit kalır.
      height: height,
      width: double.infinity,
      padding: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),

          // --- SÜRÜKLEME ÇUBUĞU (Sabit Tasarım) ---
          Container(
            width: 32.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          SizedBox(height: 24.h), // İçerik ile çubuk arası boşluk
          // --- DİNAMİK LİSTE ---
          // Gelen seçenekler listesini dönüp ekrana basıyoruz
          ...options.map((option) {
            final color = option.isDestructive
                ? AppColors
                      .primaryColor // Kırmızı (#FE6348)
                : Colors.black87;

            return Column(
              children: [
                InkWell(
                  onTap: () {
                    // Tıklanınca önce bottom sheet'i kapat, sonra aksiyonu al
                    // (veya aksiyon içinde context.pop yapabilirsin, tercih senin)
                    option.onTap();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 8.h,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option.icon,
                          size: 24.sp,
                          color: color,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            option.text,
                            style: baseTextStyle.copyWith(color: color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Son eleman değilse araya boşluk koy
                if (option != options.last) SizedBox(height: 8.h),
              ],
            );
          }),
        ],
      ),
    );
  }
}
