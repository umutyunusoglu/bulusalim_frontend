import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthInput extends StatelessWidget {
  const AuthInput({
    required this.controller,
    super.key,
    this.hintText,
    this.isPassword = false,
    this.keyboardType,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
    this.textAlign = TextAlign.center,
    this.prefixText,
    this.inputFormatters,
    this.prefixIcon,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hintText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  final TextAlign textAlign;
  final String? prefixText;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(40.r);
    final boxDecoration = BoxDecoration(
      color: const Color(0xFFF1F1F5),
      borderRadius: borderRadius,
    );

    final textStyle = TextStyle(
      fontFamily: 'SF Pro Display',
      fontSize: 14.sp,
      color: Colors.black,
      fontWeight: FontWeight.w400,
    );

    if (prefixText != null) {
      return GestureDetector(
        onTap: () {},
        child: Container(
          height: 50.h,
          decoration: boxDecoration,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                prefixText!,
                style: textStyle,
              ),
              SizedBox(width: 2.w),
              IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  obscureText: isPassword,
                  textInputAction: textInputAction,
                  keyboardType: keyboardType,
                  enabled: enabled,
                  onSubmitted: onSubmitted,
                  inputFormatters: inputFormatters,
                  cursorColor: const Color(0xFF1F4668),
                  style: textStyle,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    focusedErrorBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TextField(
      controller: controller,
      obscureText: isPassword,
      textAlign: prefixIcon != null ? TextAlign.start : textAlign,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      enabled: enabled,
      inputFormatters: inputFormatters,
      cursorColor: const Color(0xFF1F4668),
      style: textStyle,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14.sp,
        ),
        filled: true,
        fillColor: const Color(0xFFF1F1F5),

        prefixIcon: prefixIcon,
        prefixIconConstraints: BoxConstraints(
          minWidth: 48.w,
          minHeight: 24.h,
        ),

        contentPadding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 14.h,
        ),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide.none,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
