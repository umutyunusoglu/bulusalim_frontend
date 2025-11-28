import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomBottomSheetOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  CustomBottomSheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

class CustomBottomSheet extends StatelessWidget {
  const CustomBottomSheet({
    required this.options,
    super.key,
  });

  final List<CustomBottomSheetOption> options;

  /// Bu statik metot sayesinde bileşeni çağırmak çok kolaylaşır.
  /// Kullanım: CustomBottomSheet.show(context, options: [...]);
  static void show(
    BuildContext context, {
    required List<CustomBottomSheetOption> options,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true, // İçerik uzunsa kaydırmayı sağlar
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => CustomBottomSheet(options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 10.h,
        bottom:
            20.h +
            MediaQuery.of(
              context,
            ).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gri Tutma Çubuğu (Handle)
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 20.h),

          // Seçenekler Listesi
          ...options.map((option) => _buildOptionItem(context, option)),
        ],
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    CustomBottomSheetOption option,
  ) {
    // Eğer renk verilmediyse varsayılan siyah, verilirse o renk (örn: kırmızı şikayet butonu)
    final itemColor = option.color ?? Colors.black87;

    return InkWell(
      onTap: () {
        // Tıklandığında önce bottom sheet'i kapat, sonra aksiyonu al
        // (İsteğe bağlı: Navigator.pop burada da yapılabilir, çağırılan yerde de)
        option.onTap();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Row(
          children: [
            Icon(option.icon, color: itemColor, size: 24.sp),
            SizedBox(width: 16.w),
            Text(
              option.label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: itemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
