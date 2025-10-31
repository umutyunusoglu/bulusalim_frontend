import 'package:bulusalim/core/constants/constant.dart';
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
    return TextField(
      controller: controller,
      obscureText: obsecureText,
      style: kLoginTextStyle.copyWith(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        prefixIcon: iconData != null
            ? Icon(
                iconData,
                color: Colors.black,
              )
            : null,
        hintText: hintText,
        hintStyle: kLoginTextStyle.copyWith(color: Colors.black),
        filled: true,
        fillColor: const Color(0xFFF7F8F8),
        contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40.r),
          borderSide: BorderSide(
            width: 1.w,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40.r),
          borderSide: BorderSide(
            width: 1.w,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40.r),
          borderSide: BorderSide(
            width: 1.w,
          ),
        ),
      ),
    );
  }
}
