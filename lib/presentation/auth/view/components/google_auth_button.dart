import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
    super.key,
  });

  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: OutlinedButton.icon(
        onPressed: isDisabled ? null : onTap,
        icon: isLoading
            ? SizedBox(
                width: 22.h,
                height: 22.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Image.asset('assets/google.png', height: 22.h),
        label: const Text(
          'Google ile devam et',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }
}
