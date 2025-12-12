import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileGridTab extends StatelessWidget {
  const ProfileGridTab({super.key});

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    return GridView.builder(
      // Kenarlar 16, Üst 16
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 Sütun
        crossAxisSpacing: 16.w, // Yatay boşluk
        mainAxisSpacing: 16.h, // Dikey boşluk
        childAspectRatio: 1, // Kare (173x173 için)
      ),
      itemCount: 15,
      itemBuilder: (context, index) {
        // İkon Mantığı: 0. eleman Access Time, diğerleri Push Pin
        final IconData iconData = index == 0
            ? Icons.access_time_filled
            : Icons.push_pin;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. FOTOĞRAF
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                image: DecorationImage(
                  image: NetworkImage(
                    'https://picsum.photos/seed/photo$index/400/400',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // 2. SAĞ ÜST KÖŞE İKONU
            Positioned(
              top: 6.h,
              right: 4.w,
              child: Container(
                padding: EdgeInsets.all(6.r),
                child: Icon(
                  iconData,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
