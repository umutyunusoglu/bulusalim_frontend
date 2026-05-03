import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showUnfollowDialog({
  required BuildContext context,
  required String username,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        '$username hesabını takip etmeyi bırakmak istediğine emin misin?',
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Bu hesabı tekrardan takip etmek için istek tekrardan göndermen gerekecek.',
        style: TextStyle(fontSize: 14.sp),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF5D6B82),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text("Takibi Bırak"),
        ),
      ],
    ),
  );
}
