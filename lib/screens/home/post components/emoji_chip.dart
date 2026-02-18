import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmojiChip extends StatelessWidget {
  const EmojiChip({
    required this.icon,
    required this.text,
    required this.color,
    this.isSelected = false, // YENİ: Seçili durumu
    this.onTap, // YENİ: Tıklama fonksiyonu
    super.key,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Tıklama alanını garantiler
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // Renk geçiş animasyonu
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          // Seçiliyse kendi renginin şeffaf hali, değilse senin eski beyaz şeffaf rengin
          color: isSelected
              ? color.withOpacity(0.2)
              : Colors.white.withOpacity(
                  0.1,
                ), // Seçili değilken biraz daha silik yaptım
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            // Seçiliyse tam renk, değilse ince beyaz
            color: isSelected ? color : Colors.white24,
            width: isSelected
                ? 1.5
                : 1.0, // Seçilince çerçeve hafif kalınlaşsın
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              // Seçiliyse canlı renk, değilse hafif beyazımsı
              color: isSelected ? color : Colors.white.withOpacity(0.9),
              size: 14.sp,
            ),
            SizedBox(width: 10.w),
            Text(
              text,
              style: TextStyle(
                // Seçiliyse canlı renk, değilse beyaz
                color: isSelected ? color : Colors.white,
                fontFamily: 'Sf Pro Display',
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w500, // Seçilince kalınlaşsın
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
