import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TextInput extends StatelessWidget {
  const TextInput({
    super.key,
    this.iconData,
    this.hintText,
    this.obsecureText = false,
    this.controller,
  });

  final IconData? iconData;
  final String? hintText;
  final bool obsecureText;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headlineSmall;

    return TextField(
      controller: controller,
      obscureText: obsecureText,
      // Input metni stili
      style: textStyle?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontSize: 16.sp,
      ),
      decoration: InputDecoration(
        prefixIcon: iconData != null
            ? Icon(
                iconData,
                color: Colors.black,
                size: 24.sp,
              )
            : null,
        hintText: hintText,
        // Hint metni stili
        hintStyle: textStyle?.copyWith(
          color: Colors.grey.shade600,
          fontSize: 16.sp,
          fontWeight: FontWeight.normal,
        ),
        filled: true,
        fillColor: const Color(0xFFF7F8F8), // Özel gri arka plan
        contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40.r),
          borderSide: BorderSide(width: 1.w, color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40.r),
          borderSide: BorderSide(width: 1.w, color: Colors.grey.shade500),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40.r),
          borderSide: BorderSide(width: 1.w, color: Colors.black),
        ),
      ),
    );
  }
}
